// ACEOAuth2RACManager.m
//
// Copyright (c) 2016 Stefano Acerbetti - https://github.com/acerbetti/ACEOAuth2RACManager
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
#import "ACEOAuth2RACCoordinators.h"

#import "AFHTTPRequestSerializer+OAuth2.h"
#import "AFHTTPSessionManager+RACRetrySupport.h"
#import "AFNetworkActivityLogger.h"
#import "AFOAuth2Manager.h"
#import "NSURL+QueryDictionary.h"

NSTimeInterval const ACEDefaultRetryTimeInterval = 5.0;

@interface ACEOAuth2RACManager ()
// managers
@property (nonatomic, strong) AFHTTPSessionManager *networkManager;
@property (nonatomic, strong) AFOAuth2Manager *oauthManager;
@property (nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;
@property (nonatomic, strong) RACScheduler *scheduler;

// oauth
@property (nonatomic, strong) AFOAuthCredential *oauthCredential;
@property (nonatomic, copy)   RACURLSessionRetryTestBlock oauthTestBlock;
@property (nonatomic, strong) NSString *oauthRedirectURI;

// signals
@property (nonatomic, strong) RACSignal *rac_authenticate;
@property (nonatomic, strong) RACSignal *rac_networkReachabilitySignal;
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
        self.oauthManager.useHTTPBasicAuthentication = NO;
        
        self.networkManager     = [[AFHTTPSessionManager alloc] initWithBaseURL:apiBaseURL];
        
        self.reachabilityManager= [AFNetworkReachabilityManager managerForDomain:baseURL.host];
        [self.reachabilityManager startMonitoring];
        
        self.oauthRedirectURI   = [redirectURL absoluteString];
        self.oauthTestBlock = ^BOOL(NSURLResponse *response, id responseObject, NSError *error) {
            // don't retry to call the API if user is not authorized
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            return statusCode >= 401 && statusCode != 422;
        };
    }
    return self;
}


#pragma mark - Properties

- (NSURL *)authenticateURL
{
    NSURL *authenticateURL = [self.oauthManager.baseURL URLByAppendingPathComponent:self.authorizeURLString];
    return [authenticateURL uq_URLByAppendingQueryDictionary:[self authParameters]];
}

- (NSDictionary *)authParameters
{
    return @{
             @"client_id":        self.oauthManager.clientID,
             @"redirect_uri":     self.oauthRedirectURI,
             @"response_type":    @"code"
             };
}

- (RACScheduler *)scheduler
{
    if (_scheduler == nil) {
        dispatch_queue_t queue = dispatch_queue_create("com.onemob.network.queue", DISPATCH_QUEUE_SERIAL);
        _scheduler = [[RACQueueScheduler alloc] initWithName:@"com.onemob.network.scheduler" queue:queue];
    }
    return _scheduler;
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


#pragma mark - URL Paths

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


#pragma mark - Credentials

- (AFOAuthCredential *)oauthCredential
{
    if (_oauthCredential == nil) {
        if ([self.delegate respondsToSelector:@selector(retrieveCodedCredentialForNetworkManager:withIdentifier:)]) {
            // custom implementation
            NSData *data = [self.delegate retrieveCodedCredentialForNetworkManager:self
                                                                    withIdentifier:self.oauthManager.serviceProviderIdentifier];
            
            _oauthCredential = (data != nil) ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : nil;
            
        } else {
            // default implementation
            _oauthCredential = [AFOAuthCredential retrieveCredentialWithIdentifier:self.oauthManager.serviceProviderIdentifier];
        }
        
        // update the request serializer
        [self.networkManager.requestSerializer setAuthorizationHeaderFieldWithCredential:_oauthCredential];
    }
    return _oauthCredential;
}

- (void)setOauthCredential:(AFOAuthCredential *)oauthCredential
{
    if (_oauthCredential != oauthCredential) {
        _oauthCredential = oauthCredential;
        
        // update the request serializer
        [self.networkManager.requestSerializer setAuthorizationHeaderFieldWithCredential:oauthCredential];
        
        if (oauthCredential == nil) {
            
            // delete the credentials from the local store
            if ([self.delegate respondsToSelector:@selector(deleteCodedCredentialForNetworkManager:withIdentifier:)]) {
                [self.delegate deleteCodedCredentialForNetworkManager:self
                                                       withIdentifier:self.oauthManager.serviceProviderIdentifier];
                
            } else {
                // default implementation
                [AFOAuthCredential deleteCredentialWithIdentifier:self.oauthManager.serviceProviderIdentifier];
            }
            
        } else {
            
            // save it
            if ([self.delegate respondsToSelector:@selector(networkManager:storeCodedCredentials:withIdentifier:)]) {
                // custom implementation
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:oauthCredential];
                
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
}


#pragma mark - Authentication

- (RACSignal *)rac_authenticate
{
    if (self.oauthCredential != nil && !self.oauthCredential.isExpired) {
        // user credentials are not expired
        return [RACSignal return:self.oauthCredential];
        
    } else {
        // first login or expired token
        return [RACSignal startLazilyWithScheduler:self.scheduler
                                             block:^(id<RACSubscriber> subscriber) {
                                                 
                                                 if (self.oauthCredential == nil) {
                                                     ACE_LOG_DEBUG(@"Auth with coordinator");
                                                     
                                                     [[[[[self rac_authenticateWithCoordinatorSignal] subscribeOn:[RACScheduler mainThreadScheduler]]
                                                        doCompleted:^{
                                                            
                                                            if ([self.delegate respondsToSelector:@selector(networkManager:authenticatedWithType:)]) {
                                                                [self.delegate networkManager:self authenticatedWithType:[self.coordinator coordinatorType]];
                                                            }
                                                            
                                                        }] doError:^(NSError *error) {
                                                            
                                                            if ([self.delegate respondsToSelector:@selector(networkManager:failedAuthenticationWithError:forType:)]) {
                                                                [self.delegate networkManager:self failedAuthenticationWithError:error forType:[self.coordinator coordinatorType]];
                                                            }
                                                            
                                                        }] subscribe:subscriber];
                                                     
                                                 } else if (self.oauthCredential.isExpired) {
                                                     ACE_LOG_DEBUG(@"Auth with refresh token");
                                                     
                                                     NSError *error;
                                                     if ([[[self rac_authenticateWithRefreshToken:self.oauthCredential.refreshToken]
                                                           catch:^RACSignal *(NSError *error) {
                                                               if ([error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] statusCode] == 401) {
                                                                   return [self rac_authenticateWithCoordinatorSignal];
                                                                   
                                                               } else {
                                                                   return [RACSignal error:error];
                                                               }
                                                               
                                                           }] waitUntilCompleted:&error]) {
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   
                                                                   if ([self.delegate respondsToSelector:@selector(networkManager:authenticatedWithType:)]) {
                                                                       [self.delegate networkManager:self authenticatedWithType:@"RefreshToken"];
                                                                   }
                                                                   
                                                                   [subscriber sendNext:self.oauthCredential];
                                                                   [subscriber sendCompleted];
                                                               });
                                                               
                                                           } else {
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   
                                                                   if ([self.delegate respondsToSelector:@selector(networkManager:failedAuthenticationWithError:forType:)]) {
                                                                       [self.delegate networkManager:self failedAuthenticationWithError:error forType:@"RefreshToken"];
                                                                   }
                                                                   
                                                                   [subscriber sendError:error];
                                                               });
                                                           }
                                                     
                                                 } else {
                                                     [[[RACSignal return:self.oauthCredential] deliverOnMainThread] subscribe:subscriber];
                                                 }
                                             }];
    }
}

- (RACSignal *)rac_authenticateWithCoordinatorSignal
{
    @weakify(self)
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        @strongify(self)
        
        // start the authentication on the coordinator
        [self.coordinator oauthManagerWillBeginAuthentication:self withURL:[self authenticateURL]];
        
        // save a reference to the subscriber
        self.pendingSubscriber = subscriber;
        
        return nil;
        
    }] setNameWithFormat:@"[%@] -rac_authenticateWithSignal", self.class];
}

- (RACSignal *)rac_authenticateWithCode:(NSString *)oauthCode
{
    @weakify(self)
    return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
        
        @strongify(self)
        NSURLSessionTask *task =
        [self.oauthManager authenticateUsingOAuthWithURLString:self.tokenURLString
                                                          code:oauthCode
                                                   redirectURI:self.oauthRedirectURI
                                                       success:^(AFOAuthCredential *credential) {
                                                           
                                                           // store the new credentials
                                                           self.oauthCredential = credential;
                                                           
                                                           // pass the credentials in the chain
                                                           [subscriber sendNext:credential];
                                                           [subscriber sendCompleted];
                                                           
                                                       } failure:^(NSError *error) {
                                                           [subscriber sendError:error];
                                                       }];
        
        return [RACDisposable disposableWithBlock:^{
            [task cancel];
        }];
        
    }] setNameWithFormat:@"[%@] -rac_authenticateWithCode: %@", self.class, oauthCode];
}

- (RACSignal *)rac_authenticateWithRefreshToken:(NSString *)refreshToken
{
    @weakify(self)
    return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
        
        @strongify(self)
        NSURLSessionTask *task =
        [self.oauthManager authenticateUsingOAuthWithURLString:self.tokenURLString
                                                  refreshToken:refreshToken
                                                       success:^(AFOAuthCredential *credential) {
                                                           
                                                           // store the new credentials
                                                           self.oauthCredential = credential;
                                                           
                                                           // pass the credentials in the chain
                                                           [subscriber sendNext:credential];
                                                           [subscriber sendCompleted];
                                                           
                                                       } failure:^(NSError *error) {
                                                           [subscriber sendError:error];
                                                       }];
        
        return [RACDisposable disposableWithBlock:^{
            [task cancel];
        }];
        
    }] setNameWithFormat:@"[%@] -rac_authenticateWithRefreshToken: %@", self.class, refreshToken];
}

- (BOOL)handleRedirectURL:(NSURL *)redirectURL
{
    NSString *oauthCode = [redirectURL uq_queryDictionary][@"code"];
    if (oauthCode != nil && self.pendingSubscriber != nil) {
        
        @weakify(self)
        [[self rac_authenticateWithCode:oauthCode]
         subscribeNext:^(AFOAuthCredential *credential) {
             
             @strongify(self)
             
             if ([self.coordinator respondsToSelector:@selector(oauthManagerDidAuthenticate:)]) {
                 [self.coordinator oauthManagerDidAuthenticate:self];
             }
             
             // pass the credentials in the chain
             [self.pendingSubscriber sendNext:credential];
             [self.pendingSubscriber sendCompleted];
             
         } error:^(NSError *error) {
             
             if ([self.coordinator respondsToSelector:@selector(oauthManager:didFailWithError:)]) {
                 [self.coordinator oauthManager:self didFailWithError:error];
             }
             
             @strongify(self)
             [self.pendingSubscriber sendError:error];
         }];
        
        return YES;
        
    } else {
        [self.pendingSubscriber sendError:nil];
        
        return NO;
    }
}

- (void)handleRedirectError:(NSError *)error
{
    if ([self.coordinator respondsToSelector:@selector(oauthManager:didFailWithError:)]) {
        [self.coordinator oauthManager:self didFailWithError:error];
    }
    
    [self.pendingSubscriber sendError:error];
}


#pragma mark - HTTP Signals

- (RACSignal *)rac_GET:(NSString *)path parameters:(id)parameters
{
    return [self rac_GET:path parameters:parameters retries:1 interval:ACEDefaultRetryTimeInterval];
}

- (RACSignal *)rac_GET:(NSString *)path parameters:(id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval
{
    return [[self rac_authenticate] flattenMap:^RACStream *(AFOAuthCredential *credential) {
        return [[self.networkManager rac_GET:path parameters:parameters retries:retries interval:interval test:self.oauthTestBlock]
                map:^id(RACTuple *response) {
                    return [response first];
                }];
    }];
}

- (RACSignal *)rac_HEAD:(NSString *)path parameters:(id)parameters
{
    return [self rac_HEAD:path parameters:parameters retries:1 interval:ACEDefaultRetryTimeInterval];
}

- (RACSignal *)rac_HEAD:(NSString *)path parameters:(id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval
{
    return [[self rac_authenticate] flattenMap:^RACStream *(AFOAuthCredential *credential) {
        return [[self.networkManager rac_HEAD:path parameters:parameters retries:retries interval:interval test:self.oauthTestBlock]
                map:^id(RACTuple *response) {
                    return [response first];
                }];
    }];
}

- (RACSignal *)rac_POST:(NSString *)path parameters:(id)parameters
{
    return [self rac_POST:path parameters:parameters retries:1 interval:ACEDefaultRetryTimeInterval];
}

- (RACSignal *)rac_POST:(NSString *)path parameters:(id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval
{
    return [[self rac_authenticate] flattenMap:^RACStream *(AFOAuthCredential *credential) {
        return [[self.networkManager rac_POST:path parameters:parameters retries:retries interval:interval test:self.oauthTestBlock]
                map:^id(RACTuple *response) {
                    return [response first];
                }];
    }];
}

- (RACSignal *)rac_PUT:(NSString *)path parameters:(id)parameters
{
    return [self rac_PUT:path parameters:parameters retries:1 interval:ACEDefaultRetryTimeInterval];
}

- (RACSignal *)rac_PUT:(NSString *)path parameters:(id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval
{
    return [[self rac_authenticate] flattenMap:^RACStream *(AFOAuthCredential *credential) {
        return [[self.networkManager rac_PUT:path parameters:parameters retries:retries interval:interval test:self.oauthTestBlock]
                map:^id(RACTuple *response) {
                    return [response first];
                }];
    }];
}

- (RACSignal *)rac_PATCH:(NSString *)path parameters:(id)parameters
{
    return [self rac_PATCH:path parameters:parameters retries:1 interval:ACEDefaultRetryTimeInterval];
}

- (RACSignal *)rac_PATCH:(NSString *)path parameters:(id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval
{
    return [[self rac_authenticate] flattenMap:^RACStream *(AFOAuthCredential *credential) {
        return [[self.networkManager rac_PATCH:path parameters:parameters retries:retries interval:interval test:self.oauthTestBlock]
                map:^id(RACTuple *response) {
                    return [response first];
                }];
    }];
}

- (RACSignal *)rac_DELETE:(NSString *)path parameters:(id)parameters
{
    return [self rac_DELETE:path parameters:parameters retries:1 interval:ACEDefaultRetryTimeInterval];
}

- (RACSignal *)rac_DELETE:(NSString *)path parameters:(id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval
{
    return [[self rac_authenticate] flattenMap:^RACStream *(AFOAuthCredential *credential) {
        return [[self.networkManager rac_DELETE:path parameters:parameters retries:retries interval:interval test:self.oauthTestBlock]
                map:^id(RACTuple *response) {
                    return [response first];
                }];
    }];
}


#pragma mark - Other Signals

- (RACSignal *)rac_networkReachabilitySignal
{
    if (_rac_networkReachabilitySignal == nil) {
        _rac_networkReachabilitySignal = RACObserve(self.reachabilityManager, reachable);
    }
    return _rac_networkReachabilitySignal;
}

- (RACSignal *)rac_revokeTokenSignal
{
    // inform the server
    return [[[self.oauthManager rac_POST:@"/oauth/revoke"
                              parameters:@{
                                           @"token": self.oauthCredential.accessToken
                                           }
                                 retries:3
                                interval:1]
             initially:^{
                 // add the bearer
                 [self.oauthManager.requestSerializer setAuthorizationHeaderFieldWithCredential:self.oauthCredential];
                 
             }] finally:^{
                 // remove the bearer
                 self.oauthManager.requestSerializer = [AFHTTPRequestSerializer serializer];
                 
                 // clean the oauth credentials
                 self.oauthCredential = nil;
             }];
}

@end
