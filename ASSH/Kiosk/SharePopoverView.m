//
//  SharePopoverView.m
//  ASSH
//
//  Created by Sanjeev Jha on 26/04/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import "SharePopoverView.h"
#import "ASSHAppDelegate.h"

@interface SharePopoverView ()

@end

@implementation SharePopoverView

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
    
    shareBtn.layer.cornerRadius = 5;
    shareBtn.clipsToBounds = YES;
    shareBtn.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    shareBtn.layer.borderWidth = 3.0;
    
    saveAsBtn.layer.cornerRadius = 5;
    saveAsBtn.clipsToBounds = YES;
    saveAsBtn.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    saveAsBtn.layer.borderWidth = 3.0;

    clearBtn.layer.cornerRadius = 5;
    clearBtn.clipsToBounds = YES;
    clearBtn.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    clearBtn.layer.borderWidth = 3.0;
    
    removeTopic.layer.cornerRadius = 5;
    removeTopic.clipsToBounds = YES;
    removeTopic.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    removeTopic.layer.borderWidth = 3.0;
    
    if (![UIAPPDelegate isMyTopic]) {
        clearBtn.hidden=YES;
        removeTopic.hidden=YES;
        saveAsBtn.hidden=YES;
    }

    
    // Do any additional setup after loading the view from its nib.
}

-(IBAction)BtnAction:(id)sender
{
    UIButton *btn=(UIButton *)sender;
    if (btn.tag==1)
    {
        NSString *str=@"share";
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sharepopover"
                                                            object:str
                                                          userInfo:nil];
    }
    else if (btn.tag==2)
    {
        NSString *str=@"saveNewTopic";
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sharepopover"
                                                            object:str
                                                          userInfo:nil];
 
        
    }
   
    else if (btn.tag==4)
    {
        NSString *str=@"removeTopic";
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sharepopover"
                                                            object:str
                                                          userInfo:nil];
        
    }
    else if (btn.tag==5)
    {
        NSString *str=@"clearMarker";
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sharepopover"
                                                            object:str
                                                          userInfo:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
