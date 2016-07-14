// ACEOAuth2RACManagerDelegate.h
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


#import <Foundation/Foundation.h>

@class ACEOAuth2RACManager;

@protocol ACEOAuth2RACManagerCoordinator <NSObject>

- (void)oauthManagerWillBeginAuthentication:(nonnull ACEOAuth2RACManager *)manager withURL:(nonnull NSURL *)oauthURL;

@optional
- (void)oauthManagerDidAuthenticate:(nonnull ACEOAuth2RACManager *)manager;

- (void)oauthManager:(nonnull ACEOAuth2RACManager *)manager didFailWithError:(nonnull NSError *)error;

@end

#pragma mark -

/**
 `ACEOAuth2RACManagerDelegate` is a protocol to extend the network manager
 */
@protocol ACEOAuth2RACManagerDelegate <NSObject>

@optional

/**
 Retrieve the coded data with the OAuth credentials from a custom store.
 
 @param manager The network manager making the call.
 @param identifier An unique string to identify the current host.
 
 @return A coded data ready to be persisted in the custom store
 */
- (nonnull NSData *)retrieveCodedCredentialForNetworkManager:(nonnull ACEOAuth2RACManager *)manager
                                              withIdentifier:(nonnull NSString *)identifier;

/**
 Store the coded data with the OAuth credentials into a custom store.
 
 @param manager The network manager making the call.
 @param credentials The coded credentials ready to be persisted in a custom store.
 @param identifier An unique string to identify the current host.
 */
- (void)networkManager:(nonnull ACEOAuth2RACManager *)manager
 storeCodedCredentials:(nonnull NSData *)credentials
        withIdentifier:(nonnull NSString *)identifier;


/**
 Delete the coded data from the custom store.
 
 @param manager The network manager making the call.
 @param identifier An unique string to identify the current host.
 */
- (void)deleteCodedCredentialForNetworkManager:(nonnull ACEOAuth2RACManager *)manager
                                withIdentifier:(nonnull NSString *)identifier;

@end
