//
//  ListPopoverViewController.h
//  ASSH
//
//  Created by Sanjeev Jha on 13/05/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ListPopoverViewController : UIViewController
@property(nonatomic,strong)NSArray *topicsArray;
@property(nonatomic,strong) IBOutlet UITableView *table;

@end
