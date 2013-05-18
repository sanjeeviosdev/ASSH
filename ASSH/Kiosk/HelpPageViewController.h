//
//  HelpPageViewController.h
//  ASSH
//
//  Created by Sanjeev Jha on 15/05/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelpPageViewController : UIViewController
{
    IBOutlet UILabel *pageNumberLabel;
    int pageNumber;
    
    NSArray *screensArray;
   IBOutlet UIImageView *screenImageView;
}

@property (nonatomic, strong) UILabel *pageNumberLabel;
@property (nonatomic, strong) NSArray *screensArray;


- (id)initWithPageNumber:(int)page;


@end
