//
//  MypopoverView.h
//  ASSH
//
//  Created by Sanjeev Jha on 05/04/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol popoverDataDelegate <NSObject>
@optional

- (void) swichSelect:(BOOL)success;

@end
@interface MypopoverView : UIViewController
{
    IBOutlet UISwitch *switchview;

}

@property (nonatomic, unsafe_unretained) id <popoverDataDelegate> delegate;

-(IBAction)switchChange:(id)sender;
-(IBAction)Set:(id)sender;
@end
