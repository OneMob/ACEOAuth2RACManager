//
//  ViewController.m
//  ACEOAuth2RACManagerDemo
//
//  Created by Stefano Acerbetti on 2/18/16.
//  Copyright © 2016 Stefano Acerbetti. All rights reserved.
//

#import "ViewController.h"
#import "ACEOAuth2RACManager.h"

@interface ViewController ()
@property (nonatomic, strong) ACEOAuth2RACManager *m;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.m = [[ACEOAuth2RACManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://staging.onemob.co"]
                                                 clientID:@"9e41212a1616691fd89992106e6ffffe567a44ceda5ae2094b63bd72c255ed88"
                                                   secret:@"89198724c064a6033d6ccff51618893292e04ebc972c3dc74f1699bb800a52d6"
                                              redirectURL:[NSURL URLWithString:@"onemob://oauth"]
                                           oauthURLString:@"oauth"
                                             apiURLString:nil];
    
    self.m.logging = YES;
    
    self.loginButton.rac_command = [self.m rac_authenticateWithBrowser];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//
//- (IBAction)test:(id)sender
//{
//    [self.m handleRedirectURL:[NSURL URLWithString:@"http://test.com?code=123"]];
//}

@end
