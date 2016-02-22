//
//  ACEOAuth2RACManager.h
//  ACEOAuth2RACManagerDemo
//
//  Created by Stefano Acerbetti on 2/18/16.
//  Copyright © 2016 Stefano Acerbetti. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>

extern NSTimeInterval const ACEDefaultTimeInterval;

@class ACEOAuth2RACManager;

@protocol ACEOAuth2RACManagerDelegate <NSObject>

@optional
- (nonnull NSData *)retrieveCodedCredentialForNetworkManager:(nonnull ACEOAuth2RACManager *)manager;
- (void)networkManager:(nonnull ACEOAuth2RACManager *)manager storeCodedCredentials:(nonnull NSData *)credentials;

@end


@interface ACEOAuth2RACManager : NSObject

@property (nonatomic, weak) id<ACEOAuth2RACManagerDelegate> delegate;

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
- (nonnull RACSignal *)authenticate;


// HTTP methods
- (nonnull RACSignal *)rac_GET:(nonnull NSString *)path parameters:(nullable id)parameters;
- (nonnull RACSignal *)rac_GET:(nonnull NSString *)path parameters:(nullable id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval;

- (nonnull RACSignal *)rac_POST:(nonnull NSString *)path parameters:(nullable id)parameters;
- (nonnull RACSignal *)rac_POST:(nonnull NSString *)path parameters:(nullable id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval;

//- (nonnull RACSignal *)rac_HEAD:(nonnull NSString *)path parameters:(nullable id)parameters;
//- (nonnull RACSignal *)rac_HEAD:(nonnull NSString *)path parameters:(nullable id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval;

//- (nonnull RACSignal *)rac_PUT:(nonnull NSString *)path parameters:(nullable id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval;
//- (nonnull RACSignal *)rac_PATCH:(nonnull NSString *)path parameters:(nullable id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval;
//- (nonnull RACSignal *)rac_DELETE:(nonnull NSString *)path parameters:(nullable id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval;



- (BOOL)handleRedirectURL:(nonnull NSURL *)redirectURL;

@end
