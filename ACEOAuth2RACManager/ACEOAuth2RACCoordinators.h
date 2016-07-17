// ACEOAuth2RACCoordinators.h
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


#import "ACEOAuth2RACProtocols.h"

#if !ACE_APP_EXTESION

@interface ACEOAuth2RACBrowserCoordinator : NSObject<ACEOAuth2RACManagerCoordinator>

@end

#endif

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

#pragma mark - 

@interface ACEOAuth2RACWebViewCoordinator : NSObject<ACEOAuth2RACManagerCoordinator>

@property (nonatomic, strong, nullable) NSString *title;

NS_ASSUME_NONNULL_BEGIN

- (instancetype)initWithPresentingController:(nonnull UIViewController *)presentingController;
- (instancetype)init NS_UNAVAILABLE;

NS_ASSUME_NONNULL_END

@end

#endif

