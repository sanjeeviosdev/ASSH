//
//  SharePopoverView.h
//  ASSH
//
//  Created by Sanjeev Jha on 26/04/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SharePopoverView : UIViewController
{
    
    IBOutlet UIButton *shareBtn;
    IBOutlet UIButton *saveAsBtn;
    IBOutlet UIButton *clearBtn;
    IBOutlet UIButton *removeTopic;
}

-(IBAction)BtnAction:(id)sender;


@end
