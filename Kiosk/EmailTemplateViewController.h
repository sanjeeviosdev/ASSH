//
//  EmailTemplateViewController.h
//  ASSH
//
//  Created by Sanjeev Jha on 09/05/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EmailTemplateViewController : UIViewController
{
    IBOutlet UITextView *emailBodyField;
    IBOutlet UITextView *emailsignatureField;

}

-(IBAction)save:(id)sender;
-(IBAction)cancel:(id)sender;
@end
