//
//  ACEOAuth2RACManager.h
//  ACEOAuth2RACManagerDemo
//
//  Created by Stefano Acerbetti on 2/18/16.
//  Copyright © 2016 Stefano Acerbetti. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface ACEOAuth2RACManager : NSObject

@property (nonatomic, assign, getter=isLogging) BOOL logging;

@property (nonatomic, strong, nonnull) NSString *authorizeURLString;
@property (nonatomic, strong, nonnull) NSString *tokenURLString;


- (nonnull instancetype)initWithBaseURL:(nonnull NSURL *)baseURL
                               clientID:(nonnull NSString *)clientID
                                 secret:(nonnull NSString *)secret
                            redirectURL:(nullable NSURL *)redirectURL;

- (nonnull instancetype)initWithBaseURL:(nonnull NSURL *)baseURL
                               clientID:(nonnull NSString *)clientID
                                 secret:(nonnull NSString *)secret
                            redirectURL:(nullable NSURL *)redirectURL
                         oauthURLString:(nullable NSString *)oauthURLString
                           apiURLString:(nullable NSString *)apiURLString;

- (nonnull instancetype)init NS_UNAVAILABLE;




- (nonnull RACSignal *)networkReachabilitySignal;
- (nonnull RACSignal *)authenticateWithBrowserSignal;



- (BOOL)handleRedirectURL:(nonnull NSURL *)redirectURL;

@end
