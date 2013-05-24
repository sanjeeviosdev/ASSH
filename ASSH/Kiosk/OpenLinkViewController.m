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
    
    UIBarButtonItem *barbutton=[[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done)];
    
    self.navigationItem.leftBarButtonItem=barbutton;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.urlStr]];
    [self.webView loadRequest:request];
    
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)done
{
    [self.navigationController popViewControllerAnimated:NO];
}

@end
