//
//  ACEOAuth2RACManager.m
//  ACEOAuth2RACManagerDemo
//
//  Created by Stefano Acerbetti on 2/18/16.
//  Copyright © 2016 Stefano Acerbetti. All rights reserved.
//

#import "ACEOAuth2RACManager.h"
#import "AFHTTPRequestSerializer+OAuth2.h"
#import "AFHTTPSessionManager+RACRetrySupport.h"
#import "AFNetworkActivityLogger.h"
#import "AFOAuth2Manager.h"
#import "NSURL+QueryDictionary.h"


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
        
        self.networkManager     = [[AFHTTPSessionManager alloc] initWithBaseURL:apiBaseURL];
        self.oauthManager       = [[AFOAuth2Manager alloc] initWithBaseURL:oauthBaseURL clientID:clientID secret:secret];
        
        self.reachabilityManager= [AFNetworkReachabilityManager managerForDomain:baseURL.host];
        [self.reachabilityManager startMonitoring];
        
        self.oauthRedirectURI   = [redirectURL absoluteString];
    }
    return self;
}

#pragma mark - Log Activity

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
        _oauthCredential = [AFOAuthCredential retrieveCredentialWithIdentifier:self.oauthManager.serviceProviderIdentifier];
    }
    return _oauthCredential;
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
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
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




#pragma mark - RAC

- (BOOL)handleRedirectURL:(NSURL *)redirectURL
{
    NSString *oauthCode = [redirectURL uq_queryDictionary][@"code"];
    if (oauthCode != nil && self.pendingSubscriber != nil) {
        [[self rac_authenticateWithCode:oauthCode] subscribeNext:^(AFOAuthCredential *credential) {
            [self.pendingSubscriber sendNext:credential];
            [self.pendingSubscriber sendCompleted];
            
        } error:^(NSError *error) {
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
