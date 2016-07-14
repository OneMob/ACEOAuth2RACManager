// ACEOAuth2RACCoordinators.m
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


#import "ACEOAuth2RACCoordinators.h"
#import "ACEOAuth2RACManager.h"

#import "NSURL+QueryDictionary.h"

@implementation ACEOAuth2RACBrowserCoordinator

- (void)oauthManagerWillBeginAuthentication:(ACEOAuth2RACManager *)manager withURL:(NSURL *)oauthURL
{
    // open the page in an external browser
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] openURL:oauthURL];
#else
    [[NSWorkspace sharedWorkspace] openURL:oauthURL];
#endif

}

@end

#if TARGET_OS_IPHONE

#pragma mark -

@interface ACEOAuth2RACWebViewCoordinator()<UIWebViewDelegate>

@property (nonatomic, weak) ACEOAuth2RACManager *authManager;

@property (nonatomic, strong) UIViewController *presentingController;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;

@end

@implementation ACEOAuth2RACWebViewCoordinator

- (instancetype)initWithPresentingController:(nonnull UIViewController *)presentingController
{
    self = [super init];
    if (self) {
        self.presentingController = presentingController;
    }
    return self;
}

- (void)oauthManagerWillBeginAuthentication:(ACEOAuth2RACManager *)manager withURL:(NSURL *)oauthURL
{
    // set a reference for the manager
    self.authManager = manager;
    
    // load the web page
    UIWebView *webView = [UIWebView new];
    [webView setDelegate:self];
    [webView.scrollView setBounces:NO];
    [webView loadRequest:[NSURLRequest requestWithURL:oauthURL]];
    
    // create the loading indicator
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loadingView.hidesWhenStopped = YES;
    
    // prepare the container
    UIViewController *loginController = [UIViewController new];
    loginController.view = webView;
    loginController.title = self.title;
    loginController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.loadingView];
    
    // show as modal view controller
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:loginController];
    [self.presentingController presentViewController:navigationController animated:YES completion:nil];
}


#pragma mark - Web View Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSDictionary *queryDict = [request.URL uq_queryDictionary];
    if (queryDict.count == 1 && queryDict[@"code"] != nil && [self.authManager handleRedirectURL:request.URL]) {
        // dismiss the login controller
        [self.presentingController dismissViewControllerAnimated:YES completion:nil];
        
        // don't load the request here
        return NO;
        
    } else {
        // load the request
        return YES;
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.loadingView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.loadingView stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (error.code == NSURLErrorCancelled) {
        return;
    }
    
    if (error.code == 102 && [error.domain isEqual:@"WebKitErrorDomain"]) {
        return;
    }
    
    [self.authManager handleRedirectError:error];
}

@end

#endif