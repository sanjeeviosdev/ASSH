//
//  BookmarkPopoverController.h
//  ASSH
//
//  Created by Sanjeev Jha on 17/04/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSCMagazine.h"

@interface BookmarkPopoverController : UIViewController<UISearchBarDelegate,UITabBarControllerDelegate,UITableViewDataSource>

{
    
}
@property(nonatomic,strong)NSArray *bookmarkArray;
@property(nonatomic,strong)IBOutlet UITableView *bookmarkTable;
@property(nonatomic,strong)IBOutlet UIToolbar *toolBar;
@property(nonatomic,strong)IBOutlet UISearchBar *searchBar;
@property(nonatomic,strong)IBOutlet UIBarButtonItem *editButton;
@property(nonatomic,strong)NSArray *topicsArray;
@property(nonatomic,strong)NSArray *tempTopicsArray;





@end
