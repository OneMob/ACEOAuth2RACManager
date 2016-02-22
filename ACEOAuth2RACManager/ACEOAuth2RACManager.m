// ACEOAuth2RACManager.m
//
// Copyright (c) 2016 Stefano Acerbetti (https://github.com/acerbetti/ACEOAuth2RACManager)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "ACEOAuth2RACManager.h"
#import "AFHTTPRequestSerializer+OAuth2.h"
#import "AFHTTPSessionManager+RACRetrySupport.h"
#import "AFNetworkActivityLogger.h"
#import "AFOAuth2Manager.h"
#import "NSURL+QueryDictionary.h"

NSTimeInterval const ACEDefaultTimeInterval = 5.0;


@interface ACEOAuth2RACManager ()
// managers
@property (nonatomic, strong) AFHTTPSessionManager *networkManager;
@property (nonatomic, strong) AFOAuth2Manager *oauthManager;
@property (nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;

// oauth
@property (nonatomic, strong) AFOAuthCredential *oauthCredential;
@property (nonatomic, strong) NSString *oauthRedirectURI;

// signals
@property (nonatomic, strong) RACSignal *networkReachabilitySignal;
@property (nonatomic, strong) id<RACSubscriber> pendingSubscriber;

@end

#pragma mark -

@implementation ACEOAuth2RACManager

@synthesize oauthCredential = _oauthCredential;

#pragma mark -

- (instancetype)initWithBaseURL:(NSURL *)baseURL
                       clientID:(NSString *)clientID
                         secret:(NSString *)secret
                    redirectURL:(NSURL *)redirectURL
{
    return [self initWithBaseURL:baseURL clientID:clientID secret:secret redirectURL:redirectURL oauthURLString:nil apiURLString:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)baseURL
                       clientID:(NSString *)clientID
                         secret:(NSString *)secret
                    redirectURL:(NSURL *)redirectURL
                 oauthURLString:(NSString *)oauthURLString
                   apiURLString:(NSString *)apiURLString
{
    self = [super init];
    if (self) {
        NSURL *oauthBaseURL     = oauthURLString ? [baseURL URLByAppendingPathComponent:oauthURLString] : baseURL;
        NSURL *apiBaseURL       = apiURLString ? [baseURL URLByAppendingPathComponent:apiURLString] : baseURL;
        
        self.oauthManager       = [[AFOAuth2Manager alloc] initWithBaseURL:oauthBaseURL clientID:clientID secret:secret];
        self.networkManager     = [[AFHTTPSessionManager alloc] initWithBaseURL:apiBaseURL];
        [self.networkManager.requestSerializer setAuthorizationHeaderFieldWithCredential:self.oauthCredential];
        
        self.reachabilityManager= [AFNetworkReachabilityManager managerForDomain:baseURL.host];
        [self.reachabilityManager startMonitoring];
        
        self.oauthRedirectURI   = [redirectURL absoluteString];
    }
    return self;
}


#pragma mark - Logger

- (void)setLogging:(BOOL)logging
{
    if (_logging != logging) {
        _logging = logging;
        
        if (logging) {
            [[AFNetworkActivityLogger sharedLogger] startLogging];
            
        } else {
            [[AFNetworkActivityLogger sharedLogger] stopLogging];
        }
    }
}


#pragma mark - Properties

- (AFOAuthCredential *)oauthCredential
{
    if (_oauthCredential == nil) {
        if ([self.delegate respondsToSelector:@selector(retrieveCodedCredentialForNetworkManager:withIdentifier:)]) {
            // custom implementation
            NSData *data = [self.delegate retrieveCodedCredentialForNetworkManager:self
                            withIdentifier:self.oauthManager.serviceProviderIdentifier];
            
            _oauthCredential = [NSUnarchiver unarchiveObjectWithData:data];
            
        } else {
            // default implementation
            _oauthCredential = [AFOAuthCredential retrieveCredentialWithIdentifier:self.oauthManager.serviceProviderIdentifier];
        }
    }
    return _oauthCredential;
}

- (void)setOauthCredential:(AFOAuthCredential *)oauthCredential
{
    if (_oauthCredential != oauthCredential) {
        _oauthCredential = oauthCredential;
        
        // update the request serializer
        [self.networkManager.requestSerializer setAuthorizationHeaderFieldWithCredential:oauthCredential];
        
        // save it
        if ([self.delegate respondsToSelector:@selector(networkManager:storeCodedCredentials:withIdentifier:)]) {
            // custom implementation
            NSData *data = [NSArchiver archivedDataWithRootObject:oauthCredential];
            
            [self.delegate networkManager:self
                    storeCodedCredentials:data
                           withIdentifier:self.oauthManager.serviceProviderIdentifier];
            
        } else {
            // default implementation
            [AFOAuthCredential storeCredential:oauthCredential
                                withIdentifier:self.oauthManager.serviceProviderIdentifier];
        }
    }
}

- (NSString *)authorizeURLString
{
    if (_authorizeURLString == nil) {
        _authorizeURLString = @"authorize";
    }
    return _authorizeURLString;
}

- (NSString *)tokenURLString
{
    if (_tokenURLString == nil) {
        _tokenURLString = @"token";
    }
    return _tokenURLString;
}

- (NSURL *)authenticateURL
{
    NSURL *authenticateURL = [self.oauthManager.baseURL URLByAppendingPathComponent:self.authorizeURLString];
    return [authenticateURL uq_URLByAppendingQueryDictionary:@{
                                                               @"client_id":        self.oauthManager.clientID,
                                                               @"redirect_uri":     self.oauthRedirectURI,
                                                               @"response_type":    @"code"
                                                               }];
}


#pragma mark - Signals

- (RACSignal *)networkReachabilitySignal
{
    if (_networkReachabilitySignal == nil) {
        _networkReachabilitySignal = RACObserve(self.reachabilityManager, reachable);
    }
    return _networkReachabilitySignal;
}

- (RACSignal *)authenticateWithBrowserSignal
{
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self)
        
        // open the page in an external browser
#if TARGET_OS_IPHONE
        [[UIApplication sharedApplication] openURL:[self authenticateURL]];
#else
        [[NSWorkspace sharedWorkspace] openURL:[self authenticateURL]];
#endif
        
        self.pendingSubscriber = subscriber;
        
        return nil;
    }];
}

- (RACSignal *)authenticate
{
    if (self.oauthCredential == nil) {
        return [self authenticateWithBrowserSignal];
        
    } else if (self.oauthCredential.isExpired) {
        return nil;
        
    } else {
        return [RACSignal return:self.oauthCredential];
    }
}

#pragma mark - RAC

- (BOOL)handleRedirectURL:(NSURL *)redirectURL
{
    NSString *oauthCode = [redirectURL uq_queryDictionary][@"code"];
    if (oauthCode != nil && self.pendingSubscriber != nil) {
        
        @weakify(self)
        [[self rac_authenticateWithCode:oauthCode] subscribeNext:^(AFOAuthCredential *credential) {
            
            @strongify(self)
            
            // store the new credentials
            self.oauthCredential = credential;
            
            // pass the credentials in the chain
            [self.pendingSubscriber sendNext:credential];
            [self.pendingSubscriber sendCompleted];
            
        } error:^(NSError *error) {
            
            @strongify(self)
            [self.pendingSubscriber sendError:error];
        }];
        
        return YES;
        
    } else {
        [self.pendingSubscriber sendError:nil];
        
        return NO;
    }
}

//RACCommand* command = [[RACCommand alloc] initWithSignalBlock:^(id _) {
//    return [[[self.login loginSignalWithUsername:self.username password:self.password]
//             doCompleted:^{
//                 // move to next screen
//             }]
//            timeout:2.0 onScheduler:[RACScheduler mainThreadScheduler]];
//}];
//self.button.rac_command = command;


//- (RACCommand *)rac_authenticateWithBrowser
//{
//    @weakify(self)
//    return [[RACCommand alloc] initWithEnabled:[self rac_networkReachability]
//                                   signalBlock:^RACSignal *(id input) {
//                                       @strongify(self)
//                                       
//                                       // open the page in an external browser
//#if TARGET_OS_IPHONE
//                                       [[UIApplication sharedApplication] openURL:[self authenticateURL]];
//#else
//                                       [[NSWorkspace sharedWorkspace] openURL:[self authenticateURL]];
//#endif
//                                       
//                                       // save a reference of the subscriber
//                                       return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
//                                           self.pendingSubscriber = subscriber;
//                                           
//                                           return nil;
//                                       }];
//                                   }];
//}



//return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
//    
//    
//    return [RACDisposable disposableWithBlock:^{
//    }];
//    
//}] setNameWithFormat:@"[%@] -bind:", self.class];

- (RACSignal *)rac_authenticateWithCode:(NSString *)oauthCode
{
    @weakify(self)
    return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
        
        @strongify(self)
        AFHTTPRequestOperation *operation =
        [self.oauthManager authenticateUsingOAuthWithURLString:self.tokenURLString
                                                          code:oauthCode
                                                   redirectURI:self.oauthRedirectURI
                                                       success:^(AFOAuthCredential *credential) {
                                                           [subscriber sendNext:credential];
                                                           [subscriber sendCompleted];
                                                           
                                                       } failure:^(NSError *error) {
                                                           [subscriber sendError:error];
                                                       }];
        
        return [RACDisposable disposableWithBlock:^{
            [operation cancel];
        }];
        
    }] setNameWithFormat:@"[%@] -rac_authenticateWithCode: %@", self.class, oauthCode];
}

- (RACSignal *)rac_auth
{
    return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
        
        AFHTTPRequestOperation *operation;
        
        if (self.oauthCredential.isExpired) {
            operation = [self.oauthManager authenticateUsingOAuthWithURLString:self.tokenURLString
                                                      refreshToken:self.oauthCredential.refreshToken
                                                           success:^(AFOAuthCredential *credential) {
                                                               
                                                               
                                                           } failure:^(NSError *error) {
                                                               [subscriber sendError:error];
                                                           }];
            
        } else {
            operation = [self.oauthManager authenticateUsingOAuthWithURLString:self.tokenURLString
                                                                          code:@""
                                                                   redirectURI:@""
                                                                       success:^(AFOAuthCredential *credential) {
                                                                           
                                                                           
                                                                       } failure:^(NSError *error) {
                                                                           [subscriber sendError:error];
                                                                       }];
        }
        
        
        return [RACDisposable disposableWithBlock:^{
            [operation cancel];
        }];
    }];
}


- (RACSignal *)rac_GET:(NSString *)path parameters:(id)parameters
{
    return [self rac_GET:path parameters:parameters retries:1 interval:ACEDefaultTimeInterval];
}

- (RACSignal *)rac_GET:(NSString *)path parameters:(id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval
{
    return [[self authenticate] flattenMap:^RACStream *(AFOAuthCredential *credential) {
        return [[self.networkManager rac_GET:path parameters:parameters retries:retries interval:interval] map:^id(RACTuple *response) {
            return [response first];
        }];
    }];
}

- (RACSignal *)rac_POST:(NSString *)path parameters:(id)parameters
{
    return [self.networkManager rac_POST:path parameters:parameters retries:1];
}

- (RACSignal *)rac_POST:(NSString *)path parameters:(id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval
{
    return [self.networkManager rac_POST:path parameters:parameters retries:retries interval:interval];
}
    
        
//        NSURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString] parameters:parameters];
//        
//        AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:nil failure:nil];
//        RACSignal* signal = [operation rac_overrideHTTPCompletionBlock];
//        [self.operationQueue addOperation:operation];
//        [signal subscribe:subscriber];
//        return [RACDisposable disposableWithBlock:^{
//            [operation cancel];
//        }];
//    }];
//    
//    return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
//        NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:block error:nil];
//        
//        RACURLSessionRetryDataTask *task = [self URLSessionRetryDataTaskForRequest:request numberOfRetries:retries retryInterval:interval test:testBlock subscriber:subscriber];
//        
//        [task resume];
//        
//        return [RACDisposable disposableWithBlock:^{
//            [task cancel];
//        }];
//    }] setNameWithFormat:@"%@ -rac_POST: %@, parameters: %@, constructingBodyWithBlock:", self.class, path, parameters];

@end
