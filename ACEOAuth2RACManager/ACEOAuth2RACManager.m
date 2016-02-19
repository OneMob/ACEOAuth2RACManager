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
#import <ReactiveCocoa/ReactiveCocoa.h>


@interface ACEOAuth2RACManager ()
@property (nonatomic, strong) AFHTTPSessionManager *networkManager;
@property (nonatomic, strong) AFOAuth2Manager *oauthManager;
@property (nonatomic, strong) AFOAuthCredential *oauthCredential;
@property (nonatomic, strong) NSString *oauthRedirectURI;
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


#pragma mark - RAC

- (BOOL)handleRedirectURL:(NSURL *)redirectURL
{
    NSString *oauthCode = [redirectURL uq_queryDictionary][@"code"];
    if (oauthCode != nil) {
        [[self rac_authenticateWithCode:oauthCode] subscribeNext:^(AFOAuthCredential *credential) {
            
            
        } completed:^{
            
            
        }];
        
        return YES;
    }
    return NO;
}

- (RACSignal *)rac_authenticateWithCode:(NSString *)oauthCode
{
    return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
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
    }];
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
