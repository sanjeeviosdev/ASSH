//
//  EmailTemplateViewController.m
//  ASSH
//
//  Created by Sanjeev Jha on 09/05/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import "EmailTemplateViewController.h"

@interface EmailTemplateViewController ()

@end

@implementation EmailTemplateViewController

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
    self.title = @"E-Mail Template";
     self.navigationController.navigationBar.tintColor=[UIColor colorWithRed:0.847 green:0.9255 blue:0.9725 alpha:1];
    emailBodyField.layer.cornerRadius = 3;
    emailBodyField.clipsToBounds = YES;
    emailBodyField.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    emailBodyField.layer.borderWidth = 3.0;
    
    emailsignatureField.layer.cornerRadius = 3;
    emailsignatureField.clipsToBounds = YES;
    emailsignatureField.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    emailsignatureField.layer.borderWidth = 3.0;
    // Do any additional setup after loading the view from its nib.
}

-(void) viewWillAppear:(BOOL)animated{
    // Fill the e mail template body and signature if already stored
    emailBodyField.text = [[NSUserDefaults  standardUserDefaults] valueForKey:@"emailBody"];
    emailsignatureField.text = [[NSUserDefaults  standardUserDefaults] valueForKey:@"emailSignature"];
}

-(IBAction)save:(id)sender
{
    
    
    if([emailBodyField.text isEqualToString:@""] || emailBodyField==nil)
    {
        
        UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Please write email body" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
    else if([emailsignatureField.text isEqualToString:@""] || emailsignatureField==nil)
    {
        UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Please write email signature" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        
    }
    else
    {
        
        
        [[NSUserDefaults  standardUserDefaults]setObject:emailBodyField.text forKey:@"emailBody"];
        [[NSUserDefaults  standardUserDefaults]setObject:emailsignatureField.text forKey:@"emailSignature"];
        
        [self dismissModalViewControllerAnimated:YES];
        
    }
    
    
}
-(IBAction)cancel:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
 
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if (textView==emailsignatureField) {
        
        [self.view setFrame:CGRectMake(self.view.frame.origin.x, -200, self.view.frame.size.width, self.view.frame.size.height)];
    
    }

}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView==emailsignatureField) {
        
        [self.view setFrame:CGRectMake(self.view.frame.origin.x, 0, self.view.frame.size.width, self.view.frame.size.height)];
        
    }

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
