//
//  CustomNavigationController.m
//  autorotationfix
//
//  Created by John DiSalvo on 10/31/12.
//  Copyright (c) 2012 DiSalvo Technologies, LLC. All rights reserved.
//

#import "CustomNavigationController.h"

@interface CustomNavigationController ()

@end

@implementation CustomNavigationController

//- (BOOL)shouldAutorotate
//{
//    return self.topViewController.shouldAutorotate;
//}
//- (NSUInteger)supportedInterfaceOrientations
//{
//    return self.topViewController.supportedInterfaceOrientations;
//    
//    
//}



-(BOOL)shouldAutorotate
{
    return [[self.viewControllers lastObject] shouldAutorotate];
}

-(NSUInteger)supportedInterfaceOrientations
{
    return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
}


@end
