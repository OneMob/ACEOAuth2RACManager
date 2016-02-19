//
//  ACEOAuth2RACManager.m
//  ACEOAuth2RACManagerDemo
//
//  Created by Stefano Acerbetti on 2/18/16.
//  Copyright © 2016 Stefano Acerbetti. All rights reserved.
//

#import "ACEOAuth2RACManager.h"

#import "AFHTTPSessionManager+RACRetrySupport.h"
#import "AFHTTPRequestSerializer+OAuth2.h"
#import "AFOAuth2Manager.h"
#import "AFNetworkActivityLogger.h"

@interface ACEOAuth2RACManager ()
@property (nonatomic, strong) AFOAuth2Manager *oauthManager;
@property (nonatomic, strong) AFHTTPSessionManager *networkManager;
@end

#pragma mark -

@implementation ACEOAuth2RACManager

- (instancetype)initWithBaseURL:(NSURL *)url oauthPath:(NSString *)oauthPath apiPath:(NSString *)apiPath
{
    self = [super init];
    if (self) {
        self.networkManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[url URLByAppendingPathComponent:apiPath]];
        self.oauthManager = [[AFOAuth2Manager alloc] initWithBaseURL:[url URLByAppendingPathComponent:oauthPath]
                                                            clientID:@"" secret:@""];
    }
    return self;
}

- (void)setLogging:(BOOL)logging
{
    if (_logging != logging) {
        _logging = logging;
        
        if (logging) {
            [[AFNetworkActivityLogger sharedLogger] stopLogging];
            
        } else {
            [[AFNetworkActivityLogger sharedLogger] startLogging];
        }
    }
}

- (NSURL *)authorizationURL
{
    if (_authorizationURL == nil) {
        _authorizationURL = [self.oauthManager.baseURL URLByAppendingPathComponent:@"authorize"];
    }
    return _authorizationURL;
}

- (NSURL *)tokenURL
{
    if (_tokenURL == nil) {
        _tokenURL = [self.oauthManager.baseURL URLByAppendingPathComponent:@"token"];
    }
    return _tokenURL;
}

@end
