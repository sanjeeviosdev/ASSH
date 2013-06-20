//
//  MypopoverView.m
//  ASSH
//
//  Created by Sanjeev Jha on 05/04/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import "MypopoverView.h"
#import "EmailTemplateViewController.h"



@interface MypopoverView ()

@end

@implementation MypopoverView
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(IBAction)switchChange:(id)sender
{
    NSString *str;
    if (switchview.on) {
         str=@"on";
    }
    else
    {
          str=@"off";
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"GetEntity"
                                                        object:str
                                                         userInfo:nil];
    
     //[self.delegate swichSelect:YES];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
   

    // Do any additional setup after loading the view from its nib.
}
-(IBAction)Set:(id)sender
{
    EmailTemplateViewController *template=[[EmailTemplateViewController alloc] init];
    
   // template.navigationController.navigationBarHidden=NO;
    //[self presentModalViewController:template animated:YES];
    
    
   // [[NSNotificationCenter defaultCenter] postNotificationName:@"cancelpopover"
                                                     //   object:nil userInfo:nil];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:template];
    
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:navController animated:YES];
    
    
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    
    return YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
