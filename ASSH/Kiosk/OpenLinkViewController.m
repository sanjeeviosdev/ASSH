//
//  OpenLinkViewController.m
//  Hand care
//
//  Created by Sanjeev Jha on 19/05/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import "OpenLinkViewController.h"

@interface OpenLinkViewController ()

@end

@implementation OpenLinkViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"ASSH";
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.assh.org/Public/Pages/HandSurgeons.aspx"]];
    
    [self.webView loadRequest:request];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
