//
//  HelpPageViewController.m
//  ASSH
//
//  Created by Sanjeev Jha on 15/05/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import "HelpPageViewController.h"
static NSArray *__pageControlColorList = nil;
@interface HelpPageViewController ()

@end

@implementation HelpPageViewController
@synthesize pageNumberLabel;
@synthesize screensArray;

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}
// Creates the color list the first time this method is invoked. Returns one color object from the list.
+ (UIColor *)pageControlColorWithIndex:(NSUInteger)index {
    if (__pageControlColorList == nil) {
        __pageControlColorList = [[NSArray alloc] initWithObjects:[UIColor redColor], [UIColor greenColor], [UIColor magentaColor],
                                  [UIColor blueColor], [UIColor orangeColor], [UIColor brownColor], [UIColor grayColor], nil];
    }
    // Mod the index by the list length to ensure access remains in bounds.
    return [__pageControlColorList objectAtIndex:index % [__pageControlColorList count]];
}

// Load the view nib and initialize the pageNumber ivar.
- (id)initWithPageNumber:(int)page {
    if (self = [super initWithNibName:@"HelpPageViewController" bundle:nil]) {
        pageNumber = page;
    }
    return self;
}

//- (void)dealloc {
//    //[pageNumberLabel release];
//    [super dealloc];
//}

// Set the label and background color when the view has finished loading.
- (void)viewDidLoad {
    
    self.screensArray=[[NSArray alloc] initWithObjects:@"1.tiff",@"2.tiff",@"3.tiff",@"4.tiff",@"5.tiff",@"6.tiff",@"7.tiff", nil];
   // pageNumberLabel.text = [NSString stringWithFormat:@"Page %d", pageNumber + 1];
    screenImageView.image=[UIImage imageNamed:[self.screensArray objectAtIndex:pageNumber]];
   // self.view.backgroundColor = [HelpPageViewController pageControlColorWithIndex:pageNumber];
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
