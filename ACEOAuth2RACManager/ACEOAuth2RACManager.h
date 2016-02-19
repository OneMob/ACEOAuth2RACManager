//
//  ACEOAuth2RACManager.h
//  ACEOAuth2RACManagerDemo
//
//  Created by Stefano Acerbetti on 2/18/16.
//  Copyright © 2016 Stefano Acerbetti. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACEOAuth2RACManager : NSObject

@property (nonatomic, assign, getter=isLogging) BOOL logging;

@property (nonatomic, strong, nonnull) NSURL *authorizationURL;
@property (nonatomic, strong, nonnull) NSURL *tokenURL;

- (nonnull instancetype)initWithBaseURL:(nullable NSURL *)url
                              oauthPath:(nullable NSString *)oauthPath
                                apiPath:(nullable NSString *)apiPath NS_DESIGNATED_INITIALIZER;

- (nonnull instancetype)init NS_UNAVAILABLE;

@end
