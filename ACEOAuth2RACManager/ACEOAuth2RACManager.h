// ACEOAuth2RACManager.h
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


#import <ReactiveObjC/ReactiveObjC.h>
#import "ACEOAuth2RACCoordinators.h"

extern NSTimeInterval const ACEDefaultRetryTimeInterval;

@class AFHTTPSessionManager;

/**
 `ACEOAuth2RACManager` is a class that helps to manage the network connection to a server using OAuth2 for authentication
 */
@interface ACEOAuth2RACManager : NSObject

/**
 The coordinator in charge of the authentication flow
 */
@property (nonatomic, strong, nonnull) id<ACEOAuth2RACManagerCoordinator> coordinator;

/**
 The delegate to extend the manager with a different way to store the OAuth credentials
 */
@property (nonatomic, weak, nullable) id<ACEOAuth2RACManagerDelegate> delegate;

/**
 String to append to the `oauthURLString` to compose the URL to get the authentication code. Default is `authorize'
 */
@property (nonatomic, strong, nonnull) NSString *authorizeURLString;

/**
 String to append to the `oauthURLString` to compose the URL to get the OAuth credentials. Default is `token'
 */
@property (nonatomic, strong, nonnull) NSString *tokenURLString;

/**
 To track in the console log all the network calls
 */
@property (nonatomic, assign, getter=isLogging) BOOL logging;

@property (nonatomic, strong, readonly, nonnull) NSDictionary *authParameters;

@property (nonatomic, strong, readonly, nonnull) AFHTTPSessionManager *networkManager;



#pragma mark - Initialization

///---------------------
/// @name Initialization
///---------------------

NS_ASSUME_NONNULL_BEGIN

/**
 Basic init.
 
 @warning This method is unavailable.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 Initializes an `ACEOAuth2RACManager` object with the specified base URL and client information.
 
 @param baseURL The base URL for the HTTP client.
 @param clientID The OAuth client identifier.
 @param secret The OAuth secret string.
 @param redirectURL The OAuth URL used for redirection.
 
 @return The newly-initialized network manager.
 */
- (instancetype)initWithBaseURL:(nonnull NSURL *)baseURL
                       clientID:(nonnull NSString *)clientID
                         secret:(nonnull NSString *)secret
                    redirectURL:(nullable NSURL *)redirectURL;

/**
 Initializes an `ACEOAuth2RACManager` object with the specified base URL and client information.
 It also allow to specify the path for the OAuth and API endpoints.
 
 @param baseURL The base URL for the HTTP client.
 @param clientID The OAuth client identifier.
 @param secret The OAuth secret string.
 @param redirectURL The OAuth URL used for redirection.
 @param oauthURLString The URL path to connect to the OAuth api.
 @param apiURLString The URL path to connect to the server api.
 
 @return The newly-initialized network manager.
 */
- (instancetype)initWithBaseURL:(nonnull NSURL *)baseURL
                       clientID:(nonnull NSString *)clientID
                         secret:(nonnull NSString *)secret
                    redirectURL:(nullable NSURL *)redirectURL
                 oauthURLString:(nullable NSString *)oauthURLString
                   apiURLString:(nullable NSString *)apiURLString;

NS_ASSUME_NONNULL_END

#pragma mark - HTTP Signals

///-------------------
/// @name HTTP Signals
///-------------------

/**
 Set a signal to execute an HTTP `GET` asynchronously. 
 It also handle the authentication via OAuth2
 
 @param path The URL path relative to the apiURLString.
 @param parameters The optional parameters for this method.
 
 @return The signal that will execute the HTTP request asynchronously.
 */
- (nonnull RACSignal *)rac_GET:(nonnull NSString *)path parameters:(nullable id)parameters;

/**
 Set a signal to execute an HTTP `GET` asynchronously with a fixed number of retries.
 It also handle the authentication via OAuth2
 
 @param path The URL path relative to the apiURLString.
 @param parameters The optional parameters for this method.
 @param retries The desired number of retries before giving up.
 @param interval The interval between each retry.
 
 @return The signal that will execute the HTTP request asynchronously.
 */
- (nonnull RACSignal *)rac_GET:(nonnull NSString *)path parameters:(nullable id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval;

/**
 Set a signal to execute an HTTP `HEAD` asynchronously.
 It also handle the authentication via OAuth2
 
 @param path The URL path relative to the apiURLString.
 @param parameters The optional parameters for this method.
 
 @return The signal that will execute the HTTP request asynchronously.
 */
- (nonnull RACSignal *)rac_HEAD:(nonnull NSString *)path parameters:(nullable id)parameters;

/**
 Set a signal to execute an HTTP `HEAD` asynchronously with a fixed number of retries.
 It also handle the authentication via OAuth2
 
 @param path The URL path relative to the apiURLString.
 @param parameters The optional parameters for this method.
 @param retries The desired number of retries before giving up.
 @param interval The interval between each retry.
 
 @return The signal that will execute the HTTP request asynchronously.
 */
- (nonnull RACSignal *)rac_HEAD:(nonnull NSString *)path parameters:(nullable id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval;

/**
 Set a signal to execute an HTTP `POST` asynchronously.
 It also handle the authentication via OAuth2
 
 @param path The URL path relative to the apiURLString.
 @param parameters The optional parameters for this method.
 
 @return The signal that will execute the HTTP request asynchronously.
 */
- (nonnull RACSignal *)rac_POST:(nonnull NSString *)path parameters:(nullable id)parameters;

/**
 Set a signal to execute an HTTP `POST` asynchronously with a fixed number of retries.
 It also handle the authentication via OAuth2
 
 @param path The URL path relative to the apiURLString.
 @param parameters The optional parameters for this method.
 @param retries The desired number of retries before giving up.
 @param interval The interval between each retry.
 
 @return The signal that will execute the HTTP request asynchronously.
 */
- (nonnull RACSignal *)rac_POST:(nonnull NSString *)path parameters:(nullable id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval;

/**
 Set a signal to execute an HTTP `PUT` asynchronously.
 It also handle the authentication via OAuth2
 
 @param path The URL path relative to the apiURLString.
 @param parameters The optional parameters for this method.
 
 @return The signal that will execute the HTTP request asynchronously.
 */
- (nonnull RACSignal *)rac_PUT:(nonnull NSString *)path parameters:(nullable id)parameters;

/**
 Set a signal to execute an HTTP `PUT` asynchronously with a fixed number of retries.
 It also handle the authentication via OAuth2
 
 @param path The URL path relative to the apiURLString.
 @param parameters The optional parameters for this method.
 @param retries The desired number of retries before giving up.
 @param interval The interval between each retry.
 
 @return The signal that will execute the HTTP request asynchronously.
 */
- (nonnull RACSignal *)rac_PUT:(nonnull NSString *)path parameters:(nullable id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval;

/**
 Set a signal to execute an HTTP `PATCH` asynchronously.
 It also handle the authentication via OAuth2
 
 @param path The URL path relative to the apiURLString.
 @param parameters The optional parameters for this method.
 
 @return The signal that will execute the HTTP request asynchronously.
 */
- (nonnull RACSignal *)rac_PATCH:(nonnull NSString *)path parameters:(nullable id)parameters;

/**
 Set a signal to execute an HTTP `PATCH` asynchronously with a fixed number of retries.
 It also handle the authentication via OAuth2
 
 @param path The URL path relative to the apiURLString.
 @param parameters The optional parameters for this method.
 @param retries The desired number of retries before giving up.
 @param interval The interval between each retry.
 
 @return The signal that will execute the HTTP request asynchronously.
 */
- (nonnull RACSignal *)rac_PATCH:(nonnull NSString *)path parameters:(nullable id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval;

/**
 Set a signal to execute an HTTP `DELETE` asynchronously.
 It also handle the authentication via OAuth2
 
 @param path The URL path relative to the apiURLString.
 @param parameters The optional parameters for this method.
 
 @return The signal that will execute the HTTP request asynchronously.
 */
- (nonnull RACSignal *)rac_DELETE:(nonnull NSString *)path parameters:(nullable id)parameters;

/**
 Set a signal to execute an HTTP `DELETE` asynchronously with a fixed number of retries.
 It also handle the authentication via OAuth2
 
 @param path The URL path relative to the apiURLString.
 @param parameters The optional parameters for this method.
 @param retries The desired number of retries before giving up.
 @param interval The interval between each retry.
 
 @return The signal that will execute the HTTP request asynchronously.
 */
- (nonnull RACSignal *)rac_DELETE:(nonnull NSString *)path parameters:(nullable id)parameters retries:(NSInteger)retries interval:(NSTimeInterval)interval;


#pragma mark - Other Signals

///--------------------
/// @name Other Signals
///--------------------

/**
 Return a signal that check if a user has a valid session.
 
 @return The signal that monitor the user session.
 */
- (nonnull RACSignal *)rac_authenticate;


/**
 Return a signal observing the reachability of the specified host.
 
 @return The signal that monitor the network reachability.
 */
- (nonnull RACSignal *)rac_networkReachabilitySignal;


/**
 Return a signal to revoke the authentication token
 
 @return The signal to execute the command to revoke the token.
 */
- (nonnull RACSignal *)rac_revokeTokenSignal;


#pragma mark - HTTP methods

///---------------------
/// @name Authentication
///---------------------

/**
 Call this method to complete the authentication flow from the Application Delegate.
 
 @param redirectURL The URL which contains the authentication code.
 
 @return YES if the authentication code is set, NO otherwise.
 */
- (BOOL)handleRedirectURL:(nullable NSURL *)redirectURL;

- (void)handleRedirectError:(nonnull NSError *)redirectError;

@end
