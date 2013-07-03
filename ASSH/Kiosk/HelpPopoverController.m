//
//  HelpPopoverController.m
//  ASSH
//
//  Created by Sanjeev Jha on 06/04/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import "HelpPopoverController.h"
static NSUInteger kNumberOfPages = 5;
@interface HelpPopoverController (PrivateMethods)
- (void)loadScrollViewWithPage:(int)page;
- (void)scrollViewDidScroll:(UIScrollView *)sender;


@end

@implementation HelpPopoverController
@synthesize pageControl,viewControllers,scrollView;

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
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    for (unsigned i = 0; i < kNumberOfPages; i++) {
        [controllers addObject:[NSNull null]];
    }
    self.viewControllers = controllers;
    //[controllers release];
    if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
    {
        self.scrollView.frame=CGRectMake(0, 0, 657, 840);
        
        self.pageControl.frame=CGRectMake(0, 840, 657, 36);
        
        
    }
    else
    {
        /*
        self.view.frame=CGRectMake(0, 0, 800, 600);

        
        self.scrollView.frame=CGRectMake(0, 0, 800, 564);
        self.pageControl.frame=CGRectMake(0, 564, 800, 36);
        */
        self.view.frame=CGRectMake(0, 0, 800, 626);
        
        
        self.scrollView.frame=CGRectMake(0, 0, 800, 590);
        self.pageControl.frame=CGRectMake(0, 590, 800, 36);
    }

    
	
    // a page is the width of the scroll view
    self.scrollView.pagingEnabled = YES;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * kNumberOfPages, self.scrollView.frame.size.height);
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
	
    self.pageControl.numberOfPages = kNumberOfPages;
    self.pageControl.currentPage = 0;
	
    // pages are created on demand
    // load the visible page
    // load the page on either side to avoid flashes when the user starts scrolling
    
    [self loadScrollViewWithPage:0];
    [self loadScrollViewWithPage:1];

    // Do any additional setup after loading the view from its nib.
}

- (void)loadScrollViewWithPage:(int)page {
    if (page < 0) return;
    if (page >= kNumberOfPages) return;
	
    // replace the placeholder if necessary
    HelpPageViewController *controller = [self.viewControllers objectAtIndex:page];
    if ((NSNull *)controller == [NSNull null]) {
        controller = [[HelpPageViewController alloc] initWithPageNumber:page];
        [self.viewControllers replaceObjectAtIndex:page withObject:controller];
        //[controller release];
    }
	
    // add the controller's view to the scroll view
    if (nil == controller.view.superview) {
        CGRect frame = self.scrollView.frame;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0;
        controller.view.frame = frame;
        [self.scrollView addSubview:controller.view];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
    // which a scroll event generated from the user hitting the page control triggers updates from
    // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
    if (pageControlUsed) {
        // do nothing - the scroll was initiated from the page control, not the user dragging
        return;
    }
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
	
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
	
    // A possible optimization would be to unload the views+controllers which are no longer visible
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    pageControlUsed = NO;
}

- (IBAction)changePage:(id)sender {
    int page = self.pageControl.currentPage;
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
    // update the scroll view to the appropriate page
    CGRect frame = self.scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [self.scrollView scrollRectToVisible:frame animated:YES];
    // Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
    pageControlUsed = YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
