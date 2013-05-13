//
//  PSCGridController.h
//  PSPDFCatalog
//
//  Copyright 2011-2013 Peter Steinberger. All rights reserved.
//

#import "PSCBasicViewController.h"
#import "PSCStoreManager.h"
#import "MypopoverView.h"
#import "HelpPopoverController.h"
#import "BookmarkPopoverController.h"
#import "ListPopoverViewController.h"

@class PSCMagazineFolder;

// Displays a grid of elements from the PSCStoreManager
@interface PSCGridController : PSCBasicViewController <PSCStoreManagerDelegate, PSUICollectionViewDataSource, PSUICollectionViewDelegate,popoverDataDelegate,MFMailComposeViewControllerDelegate,UIGestureRecognizerDelegate>

// Designated initializer.
- (id)initWithMagazineFolder:(PSCMagazineFolder *)aMagazineFolder;

// Force-update grid.
- (void)updateGrid;

// Grid that's used internally. Either a PSCollectionView (iOS5) or UICollectionView (iOS6+)
@property (nonatomic, strong) PSUICollectionView *collectionView;
@property(nonatomic, strong)NSMutableArray *sharePdfArray;
@property(nonatomic,assign)BOOL longPressed;
@property(nonatomic,assign)BOOL clearPressed;
// Magazine-folder, if one is selected.
@property (nonatomic, strong, readonly) PSCMagazineFolder *magazineFolder;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong)BookmarkPopoverController *bookmarkPopover;
@property (nonatomic, strong)ListPopoverViewController *listPopover;

@property (nonatomic, strong) MypopoverView *myPopOver;
@property (nonatomic, strong) HelpPopoverController *helpPopOver;
@property (nonatomic, strong) NSMutableArray *markedTopics;
@property (nonatomic, strong) NSMutableArray *markedMags;
@property(nonatomic,strong)UIToolbar *tools;
@property(nonatomic,strong)UIBarButtonItem *segment;
@property(nonatomic,strong)UIBarButtonItem *titleLAbel;
@property(nonatomic,strong)UIBarButtonItem *spacer;
@property(nonatomic,strong)UIBarButtonItem *bigspacer;
@property(nonatomic,strong)UIBarButtonItem *share;
@property(nonatomic,strong)UIBarButtonItem *setting;
@property(nonatomic,strong)UIBarButtonItem *bookmark;
@property(nonatomic,strong)UIBarButtonItem *search;
@property(nonatomic,strong)UIBarButtonItem *help;
@property(nonatomic,strong)UIBarButtonItem *clear;
@property(nonatomic,strong)UISearchBar *searchBar;
@property(nonatomic,strong)UIBarButtonItem *list;
@property(nonatomic,strong) UILongPressGestureRecognizer *longPress;


- (void) changeButtonsOnTabChange:(int) tabId;
- (void)longPressItem:(UILongPressGestureRecognizer*)gesture cellIndex:(NSUInteger)cellIndex;
@end
