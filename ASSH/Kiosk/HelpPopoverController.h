//
//  HelpPopoverController.h
//  ASSH
//
//  Created by Sanjeev Jha on 06/04/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HelpPageViewController.h"

@interface HelpPopoverController : UIViewController<UIScrollViewDelegate>
{
IBOutlet UIScrollView *scrollView;
IBOutlet UIPageControl *pageControl;
NSMutableArray *viewControllers;
BOOL pageControlUsed;

}
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIPageControl *pageControl;
@property (nonatomic, retain) NSMutableArray *viewControllers;

- (IBAction)changePage:(id)sender;

@end
