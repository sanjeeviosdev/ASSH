//
//  PSCGridController.m
//  PSPDFCatalog
//
//  Copyright 2011-2013 Peter Steinberger. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PSCGridController.h"
#import "PSCImageGridViewCell.h"
#import "PSCMagazine.h"
#import "PSCMagazineFolder.h"
#import "PSCKioskPDFViewController.h"
#import "PSCSettingsController.h"
#import "PSCDownload.h"
#import "PSCImageGridViewCell.h"
#import "PSCShadowView.h"
#import "SDURLCache.h"
#import "MyPopOverView.h"
#import "ASSHAppDelegate.h"



#if !__has_feature(objc_arc)
#error "Compile this file with ARC"
#endif

#define _(string) NSLocalizedString(string, @"")

#define kPSPDFGridFadeAnimationDuration 0.3f * PSPDFSimulatorAnimationDragCoefficient()
#define kPSCLargeThumbnailSize CGSizeMake(170, 240)

// The delete button target is small enough that we don't need to ask for confirmation.
#define kPSPDFShouldShowDeleteConfirmationDialog NO

@interface PSCGridController() <UISearchBarDelegate> {
    NSArray *_filteredData;
    NSUInteger _animationCellIndex;
    BOOL _animationDoubleWithPageCurl;
    BOOL _animateViewWillAppearWithFade;
}
@property (nonatomic, assign) BOOL immediatelyLoadCellImages; // UI tweak.
@property (nonatomic, strong) UIImageView *magazineView;
@property (nonatomic, strong) PSCMagazine *lastOpenedMagazine;
@property (nonatomic, strong) PSCMagazineFolder *magazineFolder;
@property (nonatomic, strong) PSCShadowView *shadowView;
//@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@end

@implementation PSCGridController
@synthesize popoverController;
@synthesize myPopOver;
@synthesize helpPopOver;
///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)init {
    if ((self = [super init])) {
        //self.title = _(@"Patient Education Program");
       
        // one-time init stuff
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            // setup disk saving url cache
            SDURLCache *URLCache = [[SDURLCache alloc] initWithMemoryCapacity:1024*1024   // 1MB mem cache
                                                                 diskCapacity:1024*1024*5 // 5MB disk cache
                                                                     diskPath:[SDURLCache defaultCachePath]];
            URLCache.ignoreMemoryOnlyStoragePolicy = YES;
            [NSURLCache setSharedURLCache:URLCache];
        });

        // custom back button for smaller wording
      //  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:_(@"Kiosk") style:UIBarButtonItemStylePlain target:nil action:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(diskDataLoaded) name:kPSPDFStoreDiskLoadFinishedNotification object:nil];
    }
    return self;
}

- (id)initWithMagazineFolder:(PSCMagazineFolder *)aMagazineFolder {
    if ((self = [self init])) {
        self.title = aMagazineFolder.title;
        _magazineFolder = aMagazineFolder;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
   // _searchBar.delegate = nil;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationItem.hidesBackButton=YES;
    
    

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getEntity:)
                                                 name:@"GetEntity"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectBookmarkedBook:)
                                                 name:@"selectBookmark"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cancel)
                                                 name:@"cancelpopover"
                                               object:nil];
    if (!self.magazineFolder) {
       // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
    self.navigationController.navigationBar.tintColor=[UIColor colorWithRed:0.847 green:0.9255 blue:0.9725 alpha:1];
    
    self.tools = [[UIToolbar alloc]
                        initWithFrame:CGRectMake(0.0f, 0.0f, 1024.0f, 44.01f)]; // 44.01 shifts it up 1px for some reason
    self.tools.clearsContextBeforeDrawing = NO;
    self.tools.clipsToBounds = NO;
    self.tools.tintColor = [UIColor colorWithWhite:0.305f alpha:0.0f]; // closest I could get by eye to black, translucent style.
    // anyone know how to get it perfect?
    self.tools.barStyle = -1; // clear background
    
    // Create a segment control
    
    UISegmentedControl *seg1 = [[UISegmentedControl alloc]
                                initWithItems:[NSArray arrayWithObjects:@"Topics", @"My Topics", nil]];
    [seg1 addTarget:self action:@selector(onSegmentChanged:) forControlEvents:UIControlEventValueChanged];
    seg1.selectedSegmentIndex=0;
    seg1.frame=CGRectMake(0, 0, 200, 30);
    seg1.tintColor=[UIColor colorWithRed:0.847 green:0.9255 blue:0.9725 alpha:1];
     self.segment = [[UIBarButtonItem alloc] initWithCustomView:seg1];
    
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0,0,45,45)];
    label.textColor = [UIColor grayColor];
    label.backgroundColor=[UIColor clearColor];
    label.text=@"Patient Education Program"; //CUSTOM TITLE
    [label sizeToFit];
    
    self.titleLAbel = [[UIBarButtonItem alloc] initWithCustomView:label];
    
    self.spacer = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                               target:nil
                               action:nil];
    self.spacer.width=10;
    
    self.bigspacer = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                               target:nil
                               action:nil];
    self.bigspacer.width=40;
   
    UIButton *shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *shareBtnImage = [UIImage imageNamed:@"share.png"];
    [shareBtn setBackgroundImage:shareBtnImage forState:UIControlStateNormal];
    [shareBtn addTarget:self action:@selector(shareAction) forControlEvents:UIControlEventTouchUpInside];
    [shareBtn setFrame:CGRectMake(0, 0, 60, 30)];
    self.share = [[UIBarButtonItem alloc] initWithCustomView:shareBtn];
    
    UIButton *settingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *backBtnImage = [UIImage imageNamed:@"setting.png"];
        [settingBtn setBackgroundImage:backBtnImage forState:UIControlStateNormal];
        [settingBtn addTarget:self action:@selector(settingAction) forControlEvents:UIControlEventTouchUpInside];
        settingBtn.frame = CGRectMake(0, 0, 33, 29);
     self.setting = [[UIBarButtonItem alloc] initWithCustomView:settingBtn];

    
    UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *clearBtnImage = [UIImage imageNamed:@"clear.png"];
    
    [clearBtn setBackgroundImage:clearBtnImage forState:UIControlStateNormal];
    [clearBtn addTarget:self action:@selector(clearAction) forControlEvents:UIControlEventTouchUpInside];
    clearBtn.frame = CGRectMake(0, 0, 40, 30);
    //[tools addSubview:contentBtn];
    self.clear = [[UIBarButtonItem alloc] initWithCustomView:clearBtn];
    //[buttons addObject:content];
    
    UIButton *bookmarkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *bookmarkBtnImage = [UIImage imageNamed:@"bookmark1.png"];
    [bookmarkBtn setBackgroundImage:bookmarkBtnImage forState:UIControlStateNormal];
    [bookmarkBtn addTarget:self action:@selector(bookmarkAction) forControlEvents:UIControlEventTouchUpInside];
    bookmarkBtn.frame = CGRectMake(0, 0, 32,25 );
    self.bookmark = [[UIBarButtonItem alloc] initWithCustomView:bookmarkBtn];
    //[buttons addObject:bookmark];
    
    
    //[tools addSubview:bookmarkBtn];
    self.searchBar=[[UISearchBar alloc] init];
    [self.searchBar setFrame:CGRectMake(775,10,220,25)];
    self.searchBar.delegate=self;
     self.search = [[UIBarButtonItem alloc] initWithCustomView:self.searchBar];
    //[tools addSubview:searchbar];
    
    UIButton *helpBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *helpBtnImage = [UIImage imageNamed:@"help1.png"];

    [helpBtn setBackgroundImage:helpBtnImage forState:UIControlStateNormal];
    [helpBtn addTarget:self action:@selector(helpAction) forControlEvents:UIControlEventTouchUpInside];
    helpBtn.frame = CGRectMake(0, 0, 30, 30);
   // [tools addSubview:helpBtn];
    self.help = [[UIBarButtonItem alloc] initWithCustomView:helpBtn];
   // [buttons addObject:help];
    
    [self.tools setItems:[NSArray arrayWithObjects: self.spacer, self.segment, self.spacer, self.share,self.bigspacer,self.titleLAbel,self.bigspacer,self.bookmark,self.spacer,self.setting,self.spacer,self.search,self.spacer,self.help ,nil] animated:NO];
    
  UIBarButtonItem *custom = [[UIBarButtonItem alloc] initWithCustomView:self.tools];
    //[self.navigationController.navigationBar addSubview:tools];
    
    self.navigationItem.leftBarButtonItem = custom;
    
    self.navigationController.navigationBar.tintColor=[UIColor colorWithRed:0.847 green:0.9255 blue:0.9725 alpha:1];
    [self changeButtonsOnTabChange:0];
    
#ifdef PSPDFCatalog

#endif

    // Add global shadow.
    CGFloat toolbarHeight = self.navigationController.navigationBar.frame.size.height;
    self.shadowView = [[PSCShadowView alloc] initWithFrame:CGRectMake(0, -toolbarHeight, self.view.bounds.size.width, toolbarHeight)];
    _shadowView.shadowOffset = toolbarHeight;
    _shadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _shadowView.backgroundColor = [UIColor clearColor];
    _shadowView.userInteractionEnabled = NO;
    [self.view addSubview:_shadowView];

    // Use custom view to match background with PSPDFViewController.
    UIView *backgroundTextureView = [[UIView alloc] initWithFrame:CGRectMake(0, -toolbarHeight, self.view.bounds.size.width, self.view.bounds.size.height + toolbarHeight)];
    backgroundTextureView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    backgroundTextureView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen_texture_dark"]];
    [self.view insertSubview:backgroundTextureView belowSubview:_shadowView];

    // Init the collection view.
    PSUICollectionViewFlowLayout *flowLayout = [PSUICollectionViewFlowLayout new];
    PSUICollectionView *collectionView = [[PSUICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    
    flowLayout.minimumLineSpacing = 30;
    
    NSUInteger spacing = 14;
    flowLayout.minimumInteritemSpacing = spacing;
    flowLayout.sectionInset = UIEdgeInsetsMake(spacing, spacing, spacing, spacing);

    [collectionView registerClass:[PSCImageGridViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PSCImageGridViewCell class])];
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.collectionView = collectionView;

    [self.view insertSubview:self.collectionView belowSubview:_shadowView];
    self.collectionView.frame = CGRectIntegral(self.view.bounds);
    self.collectionView.dataSource = self; // auto-reloads
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;

    // Add the search bar.
   // CGFloat searchBarWidth = 290.f;
//    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectIntegral(CGRectMake((self.collectionView.bounds.size.width-searchBarWidth)/2, -44.f, searchBarWidth, 44.f))];
//    _searchBar.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
//    _searchBar.tintColor = [UIColor blackColor];
//    _searchBar.backgroundColor = [UIColor clearColor];
//    _searchBar.alpha = 0.5;
//    _searchBar.delegate = self;

    // Doesn't matter much if this fails, but the background doesn't look great within our grid.
    //[PSPDFGetViewInsideView(_searchBar, @"UISearchBarBack") removeFromSuperview];

    // Set the return key and keyboard appearance of the search bar.
    // Since we do live-filtering, the search bar should just dismiss the keyboard.
    for (UITextField *searchBarTextField in [_searchBar subviews]) {
        if ([searchBarTextField conformsToProtocol:@protocol(UITextInputTraits)]) {
            @try {
                searchBarTextField.enablesReturnKeyAutomatically = NO;
                searchBarTextField.keyboardAppearance = UIKeyboardAppearanceAlert;
            }
            @catch (NSException * e) {} break;
        }
    }

    //self.collectionView.contentInset = UIEdgeInsetsMake(64.f, 0, 0, 0);
  //  [self.collectionView addSubview:self.searchBar];
}


- (void) changeButtonsOnTabChange:(int) tabId{
    if (tabId == 0) {
        [self.tools setItems:[NSArray arrayWithObjects: self.spacer, self.segment, self.spacer, self.bigspacer, self.bigspacer,  self.bigspacer,self.spacer,self.titleLAbel,self.bigspacer,self.bookmark,self.spacer,self.setting,self.spacer,self.search,self.spacer,self.help ,nil] animated:NO];
    } else {
        [self.tools setItems:[NSArray arrayWithObjects: self.spacer, self.segment, self.spacer, self.share, self.bigspacer,  self.spacer,self.titleLAbel,self.bigspacer,self.bookmark,self.spacer,self.setting,self.spacer,self.search,self.spacer,self.help ,nil] animated:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    if (!self.isViewLoaded) {
        self.collectionView.delegate = nil;
        self.collectionView.dataSource = nil;
        self.collectionView = nil;
        self.shadowView = nil;
        self.searchBar.delegate = nil;
        self.searchBar = nil;
    }
}


-(void)shareAction
{
    if ([self.sharePdfArray count]>0) {
        
        if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
        mailController.mailComposeDelegate = self;
         NSString * pdfname=@"";
        for (NSString *pdf in self.sharePdfArray) {
            
          // NSString *justFileName = [pdf stringByReplacingOccurrencesOfString:@".pdf" withString:@""];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *FolderPath = [documentsDirectory stringByAppendingPathComponent:@"MyTopics"];
            NSString* FilePath = [FolderPath stringByAppendingPathComponent:pdf];
                                  
                                                            
            pdfname=[pdfname stringByAppendingString:pdf];
            pdfname=[pdfname stringByAppendingString:@", "];
            NSData *pdfData = [NSData dataWithContentsOfFile:FilePath];
            [mailController addAttachmentData:pdfData mimeType:@"application/pdf"fileName:pdf];
        }
        pdfname = [NSString stringWithFormat:@"%@.",pdfname];
        pdfname = [pdfname stringByReplacingOccurrencesOfString:@", ." withString:@""];
        [mailController setSubject:pdfname];
         NSString *mailBody =   [[NSUserDefaults  standardUserDefaults]objectForKey:@"emailBody"];
            
         NSString *mailSignature = [[NSUserDefaults  standardUserDefaults]objectForKey:@"emailSignature"];
            if([mailBody isEqualToString:@"" ])
            {
                mailBody=@"This mail is sent by ASSH Application";
            }
            
            NSString *finalEmailbody=[NSString stringWithFormat:@"%@ \n\n\n %@ ",mailBody,mailSignature];
       
        [mailController setMessageBody:finalEmailbody isHTML:NO];
         
        [self presentViewController:mailController animated:YES completion:nil];
        }
        else{
            UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"Share" message:@"No mail client configured on this device. Kindly configure any mail id before using the share option" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            
            [alert show];
            
        }
    }
    else{
        UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"Share" message:@"Please select the topic" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        
        [alert show];
    }


}
-(void)clearAction

{
//    for (int i=0; i<[_filteredData count]; i++) {
//    
//
//
//     PSCImageGridViewCell *cell = (PSCImageGridViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
//    
//   
//            
//            UIButton *btn1=(UIButton *)[self.view viewWithTag:cell.tag+1000];
//            UIButton *btn2=(UIButton *)[self.view viewWithTag:cell.tag+2000];
//            if (btn1) {
//                [btn1 removeFromSuperview];
//                
//            }
//            if (btn2){
//                
//                [btn2 removeFromSuperview];
//                
//            }
//            
//        }
    

    self.longPressed=NO;

    self.clearPressed=YES;
    [self.sharePdfArray removeAllObjects];
    
    [self.tools setItems:[NSArray arrayWithObjects: self.spacer, self.segment, self.spacer, self.share,self.bigspacer,self.titleLAbel,self.bigspacer,self.bookmark,self.spacer,self.setting,self.spacer,self.search,self.spacer,self.help ,nil] animated:NO];
    

    
    // Ensure everything is up to date (we could change magazines in other controllers)
    self.immediatelyLoadCellImages = YES;
    [self diskDataLoaded]; // also reloads the grid
    self.immediatelyLoadCellImages = NO;
    
    if (_animateViewWillAppearWithFade) {
        [self.navigationController.view.layer addAnimation:PSPDFFadeTransition() forKey:kCATransition];
        _animateViewWillAppearWithFade = NO;
    }
    
    [self setProgressIndicatorVisible:PSCStoreManager.sharedStoreManager.isDiskDataLoaded animated:NO];
    
    [ self updateGrid ];
    
   
}
-(void)bookmarkAction
{
    if(![popoverController isPopoverVisible]){
        self.bookmarkPopover = [[BookmarkPopoverController alloc] initWithNibName:@"BookmarkPopoverController" bundle:nil];
        self.bookmarkPopover.tempTopicsArray=_filteredData;
        popoverController = [[UIPopoverController alloc] initWithContentViewController:self.bookmarkPopover];
        //[popoverController setDelegate:self];
        [popoverController setPopoverContentSize:CGSizeMake(360.0f, 500.0f)];
        if (self.view.window != nil)
            [popoverController presentPopoverFromRect:CGRectMake(600, -105, 111, 111) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        
    }else {
        [popoverController dismissPopoverAnimated:YES];
        popoverController.delegate=nil;
    }
    

    
    
}
-(void)helpAction
{
    if(![popoverController isPopoverVisible]){
    helpPopOver = [[HelpPopoverController alloc] initWithNibName:@"HelpPopoverController" bundle:nil];
    popoverController = [[UIPopoverController alloc] initWithContentViewController:helpPopOver];
    //[popoverController setDelegate:self];
    [popoverController setPopoverContentSize:CGSizeMake(500.0f, 800.0f)];
    if (self.view.window != nil)
        [popoverController presentPopoverFromRect:CGRectMake(900, -105, 111, 111) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
}else{
    [popoverController dismissPopoverAnimated:YES];
    popoverController.delegate=nil;
}

    
}

-(void)settingAction
{
    if(![popoverController isPopoverVisible]){
		myPopOver = [[MypopoverView alloc] initWithNibName:@"MypopoverView" bundle:nil];
		popoverController = [[UIPopoverController alloc] initWithContentViewController:myPopOver];
		//[popoverController setDelegate:self];
		[popoverController setPopoverContentSize:CGSizeMake(350.0f, 150.0f)];
        if (self.view.window != nil)
            [popoverController presentPopoverFromRect:CGRectMake(630, -105, 111, 111) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
		
	}else{
		[popoverController dismissPopoverAnimated:YES];
        popoverController.delegate=nil;
	}

}
-(void)cancel
{
    [popoverController dismissPopoverAnimated:YES];
 
}

- (void)selectBookmarkedBook:(NSNotification *)notif {
    [popoverController dismissPopoverAnimated:YES];

    PSCMagazine *mag=(PSCMagazine *)[notif object];
    [self openMagazine:mag];
    
    
}

- (void)getEntity:(NSNotification *)notif {
    NSString *str = (NSString *)[notif object];
    
    NSLog(@"str===%@",str);
    
    if ([str isEqualToString:@"on"]) {
        
        [UIAPPDelegate setIsSorting:YES];
        [[PSCStoreManager sharedStoreManager] loadMagazinesFromDisk];
        
        [PSCStoreManager sharedStoreManager].delegate = self;
        
        // Ensure everything is up to date (we could change magazines in other controllers)
        self.immediatelyLoadCellImages = YES;
        [self diskDataLoaded]; // also reloads the grid
        self.immediatelyLoadCellImages = NO;
        
        if (_animateViewWillAppearWithFade) {
            [self.navigationController.view.layer addAnimation:PSPDFFadeTransition() forKey:kCATransition];
            _animateViewWillAppearWithFade = NO;
        }
        
        [self setProgressIndicatorVisible:PSCStoreManager.sharedStoreManager.isDiskDataLoaded animated:NO];
        
   [ self updateGrid ];
        
    }
    else
    {
        [UIAPPDelegate setIsSorting:NO];
         [[PSCStoreManager sharedStoreManager] loadMagazinesFromDisk];
        [PSCStoreManager sharedStoreManager].delegate = self;
        
        // Ensure everything is up to date (we could change magazines in other controllers)
        self.immediatelyLoadCellImages = YES;
        [self diskDataLoaded]; // also reloads the grid
        self.immediatelyLoadCellImages = NO;
        
        if (_animateViewWillAppearWithFade) {
            [self.navigationController.view.layer addAnimation:PSPDFFadeTransition() forKey:kCATransition];
            _animateViewWillAppearWithFade = NO;
        }
        
        [self setProgressIndicatorVisible:PSCStoreManager.sharedStoreManager.isDiskDataLoaded animated:NO];
        [ self updateGrid ];
 
    }
}
- (void)onSegmentChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    if (segment.selectedSegmentIndex == 0) {
        [UIAPPDelegate setIsMyTopic:NO];
        
        [[PSCStoreManager sharedStoreManager] loadMagazinesFromDisk];
        
        [PSCStoreManager sharedStoreManager].delegate = self;
        
        // Ensure everything is up to date (we could change magazines in other controllers)
        self.immediatelyLoadCellImages = YES;
        [self diskDataLoaded]; // also reloads the grid
        self.immediatelyLoadCellImages = NO;
        
        if (_animateViewWillAppearWithFade) {
            [self.navigationController.view.layer addAnimation:PSPDFFadeTransition() forKey:kCATransition];
            _animateViewWillAppearWithFade = NO;
        }
        
        [self setProgressIndicatorVisible:PSCStoreManager.sharedStoreManager.isDiskDataLoaded animated:NO];
        
        [ self updateGrid ];
        
        
    }
    else if (segment.selectedSegmentIndex == 1) {
        [UIAPPDelegate setIsMyTopic:YES];
        [[PSCStoreManager sharedStoreManager] loadMagazinesFromDisk];
        
        [PSCStoreManager sharedStoreManager].delegate = self;
        
        // Ensure everything is up to date (we could change magazines in other controllers)
        self.immediatelyLoadCellImages = YES;
        [self diskDataLoaded]; // also reloads the grid
        self.immediatelyLoadCellImages = NO;
        
        if (_animateViewWillAppearWithFade) {
            [self.navigationController.view.layer addAnimation:PSPDFFadeTransition() forKey:kCATransition];
            _animateViewWillAppearWithFade = NO;
        }
        
        [self setProgressIndicatorVisible:PSCStoreManager.sharedStoreManager.isDiskDataLoaded animated:NO];
        
        [ self updateGrid ];
        
    }
    [self changeButtonsOnTabChange:segment.selectedSegmentIndex];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
 self.sharePdfArray=[[NSMutableArray alloc] init];
    // Ensure our navigation bar is visible. PSPDFKit restores the properties,
    // But since we're doing a custom fade-out on the navigationBar alpha,
    // We also have to restore this properly.
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [UIView animateWithDuration:0.25f animations:^{
        self.navigationController.navigationBar.alpha = 1.f;
    }];
    [UIApplication.sharedApplication setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [UIApplication.sharedApplication setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    _shadowView.shadowEnabled = YES;

    // If navigationBar is offset, we're fixing that.
    PSPDFFixNavigationBarForNavigationControllerAnimated(self.navigationController, animated);

    // Only one delegate at a time (only one grid is displayed at a time)
    [[PSCStoreManager sharedStoreManager] loadMagazinesFromDisk];
    
    [PSCStoreManager sharedStoreManager].delegate = self;
    // Ensure everything is up to date (we could change magazines in other controllers)
    self.immediatelyLoadCellImages = YES;
    [self diskDataLoaded]; // also reloads the grid
    self.immediatelyLoadCellImages = NO;

    if (_animateViewWillAppearWithFade) {
        [self.navigationController.view.layer addAnimation:PSPDFFadeTransition() forKey:kCATransition];
        _animateViewWillAppearWithFade = NO;
    }
    self.markedTopics = [UIAPPDelegate fetchBookmarks];

    [self setProgressIndicatorVisible:PSCStoreManager.sharedStoreManager.isDiskDataLoaded animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // If navigationBar is offset, we're fixing that.
    PSPDFFixNavigationBarForNavigationControllerAnimated(self.navigationController, animated);

    // Animate back to grid cell?
    if (self.magazineView) {
        // If something changed, just don't animate.
        if (_animationCellIndex >= self.magazineFolder.magazines.count) {
            self.collectionView.transform = CGAffineTransformIdentity;
            self.collectionView.alpha = 1.0f;
            [self.view.layer addAnimation:PSPDFFadeTransition() forKey:kCATransition];
            [self.magazineView removeFromSuperview];
            self.magazineView = nil;
        }else {
            
           // [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:_animationCellIndex inSection:0] atScrollPosition:PSTCollectionViewScrollPositionCenteredHorizontally animated:NO];
            
            [self.collectionView layoutSubviews]; // ensure cells are laid out
            /*
             // ensure object is visible
             BOOL isCellVisible = [self.gridView isCellVisibleAtIndex:_animationCellIndex partly:YES];
             if (!isCellVisible) {
             [self.gridView scrollToObjectAtIndex:_animationCellIndex atScrollPosition:PSPDFGridViewScrollPositionTop animated:NO];
             [self.gridView layoutSubviews]; // ensure cells are laid out
             };*/

            // Convert the coordinates into view coordinate system.
            // We can't remember those, because the device might has been rotated.
            CGRect absoluteCellRect = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_animationCellIndex inSection:0]].frame;
            CGRect relativeCellRect = [self.collectionView convertRect:absoluteCellRect toView:self.view];

            self.magazineView.frame = [self magazinePageCoordinatesWithDoublePageCurl:_animationDoubleWithPageCurl && UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation)];

            // Update image for a nicer animation (get the correct page)
            UIImage *coverImage = [self imageForMagazine:self.lastOpenedMagazine];
            if (coverImage) self.magazineView.image = coverImage;

            // Start animation!
            [UIView animateWithDuration:0.3f delay:0.f options:0 animations:^{
                self.collectionView.transform = CGAffineTransformIdentity;
                self.magazineView.frame = relativeCellRect;
                [[self.magazineView.subviews lastObject] setAlpha:0.f];
                self.collectionView.alpha = 1.0f;
            } completion:^(BOOL finished) {
                [self.magazineView removeFromSuperview];
                self.magazineView = nil;
            }];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // Only deregister if not attached to anything else.
    if ([PSCStoreManager sharedStoreManager].delegate == self) [PSCStoreManager sharedStoreManager].delegate = nil;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

- (void)updateGrid {
    BOOL restoreKeyboard = NO;   if ([self.searchBar isFirstResponder]) {
       restoreKeyboard = YES;
    }

    [self.collectionView reloadData];

    // UICollectionView is stealing the first responder.
    if (restoreKeyboard) {
        [self.searchBar becomeFirstResponder];
   }
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Progress display

- (void)setProgressIndicatorVisible:(BOOL)visible animated:(BOOL)animated {
    if (visible){
        if (!self.activityView){
            UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            [activityView sizeToFit];
            activityView.frame = PSPDFAlignRectangles(activityView.frame, self.view.frame, PSPDFRectAlignCenter);
            activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
            [activityView startAnimating];
            self.activityView = activityView;
        }
    }
    if (visible) {
        self.activityView.alpha = 0.f;
        [self.view addSubview:self.activityView];
    }
    [UIView animateWithDuration:animated ? 0.25f : 0.f delay:0.f options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:^{
        self.activityView.alpha = visible ? 1.f : 0.f;
    } completion:^(BOOL finished) {
        if (finished && !visible) {
            [self.activityView removeFromSuperview];
        }
    }];
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

- (void)presentModalViewControllerWithCloseButton:(UIViewController *)controller animated:(BOOL)animated {
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    controller.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:PSPDFLocalize(@"Close") style:UIBarButtonItemStyleBordered target:self action:@selector(closeModalView)];
    [self presentViewController:navController animated:animated completion:NULL];
}

// toggle the options/settings button.
- (void)optionsButtonPressed {
    BOOL alreadyDisplayed = PSPDFIsControllerClassInPopoverAndVisible(self.popoverController, [PSCSettingsController class]);
    if (alreadyDisplayed) {
        [self.popoverController dismissPopoverAnimated:YES];
        self.popoverController = nil;
    }else {
        PSCSettingsController *settingsController = [PSCSettingsController new];
        settingsController.owningViewController = self;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsController];
        if (PSIsIpad()) {
            self.popoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
            [self.popoverController presentPopoverFromBarButtonItem:self.navigationItem.leftBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }else {
            [self presentModalViewControllerWithCloseButton:settingsController animated:YES];
        }
    }
}

// calculates where the document view will be on screen
- (CGRect)magazinePageCoordinatesWithDoublePageCurl:(BOOL)doublePageCurl {
    CGRect newFrame = self.view.frame;
    newFrame.origin.y -= self.navigationController.navigationBar.frame.size.height;
    newFrame.size.height += self.navigationController.navigationBar.frame.size.height;

    // compensate for transparent statusbar. Change this var if you're not using PSPDFStatusBarSmartBlackHideOnIpad
    BOOL iPadFadesOutStatusBar = YES;
    if (!PSIsIpad() || iPadFadesOutStatusBar) {
        CGRect statusBarFrame = [UIApplication.sharedApplication statusBarFrame];
        BOOL isPortrait = UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication.statusBarOrientation);
        CGFloat statusBarHeight = isPortrait ? statusBarFrame.size.height : statusBarFrame.size.width;
        newFrame.origin.y -= statusBarHeight;
        newFrame.size.height += statusBarHeight;
    }

    // animation needs to be different if we are in pageCurl mode
    if (doublePageCurl) {
        newFrame.size.width /= 2;
        newFrame.origin.x += newFrame.size.width;
    }

    return newFrame;
}

- (UIImage *)imageForMagazine:(PSCMagazine *)magazine {
    if (!magazine) return nil;

    NSUInteger lastPage = magazine.lastViewState.page;
    UIImage *coverImage = [PSPDFCache.sharedCache imageFromDocument:magazine andPage:lastPage withSize:UIScreen.mainScreen.bounds.size options:PSPDFCacheOptionDiskLoadSync|PSPDFCacheOptionRenderSync|PSPDFCacheOptionMemoryStoreAlways];
    return coverImage;
}


/*
// Open magazine with a nice animation.
- (BOOL)openMagazine:(PSCMagazine *)oldMagazine animated:(BOOL)animated cellIndex:(NSUInteger)cellIndex {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentDBFolderPath = [documentsDirectory stringByAppendingPathComponent:@"MyTopics"];
    NSString *tempName = [NSString stringWithFormat:@"temp_%@",[oldMagazine.files lastObject]];
    documentDBFolderPath =[documentDBFolderPath stringByAppendingPathComponent:tempName];
    NSURL *destFileURL = [NSURL URLWithString:[documentDBFolderPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    //[destFileURL URLByAppendingPathComponent:@"temp.pdf"];
    
    NSString *resourceDBFolderPath = [[oldMagazine.basePath URLByAppendingPathComponent:[oldMagazine.files lastObject]] path];
   // NSString *resourceDBFolderPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Samples"];
    //resourceDBFolderPath=[resourceDBFolderPath stringByAppendingPathComponent:tempName];
    
    [fileManager copyItemAtPath:resourceDBFolderPath toPath:[destFileURL path] error:&error];
    
    //PSCMagazine *magazine = [[PSCMagazine alloc] initWithData:[NSData dataWithContentsOfFile:[destFileURL path]]];
   // magazine.title = oldMagazine.fileName;
    PSCMagazine *magazine = [[PSCMagazine alloc] initWithURL:destFileURL];
    magazine.title = oldMagazine.fileName;
    self.lastOpenedMagazine = magazine;
   // [self.searchBar resignFirstResponder];
    magazine.overrideClassNames = @{(id)[PSPDFBookmarkParser class] : [PSCBookmarkParser class]};


    // Speed up displaying with parsing several things PSPDFViewController needs.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [magazine fillCache];
    });

    PSCKioskPDFViewController *pdfController = [[PSCKioskPDFViewController alloc] initWithDocument:magazine];


    // Try to get full-size image, if that fails try thumbnail.
    UIImage *coverImage = [self imageForMagazine:magazine];
    if (animated && coverImage && !magazine.isLocked) {
        PSUICollectionViewCell *cell = (PSUICollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:cellIndex inSection:0]];
        cell.hidden = YES;
        CGRect cellCoords = [self.collectionView convertRect:cell.frame toView:self.view];
        UIImageView *coverImageView = [[UIImageView alloc] initWithImage:coverImage];
        
        
        coverImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        coverImageView.frame = cellCoords;
        
        

        coverImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:coverImageView];
        self.magazineView = coverImageView;
        _animationCellIndex = cellIndex;

        // Add a smooth status bar transition on the iPhone
        if (!PSIsIpad()) {
            [UIApplication.sharedApplication setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
        }

        // If we have a different page, fade to that page.
        UIImageView *targetPageImageView = nil;
        if (pdfController.page != 0 && !pdfController.isDoublePageMode) {
            UIImage *targetPageImage = [PSPDFCache.sharedCache imageFromDocument:magazine andPage:pdfController.page withSize:UIScreen.mainScreen.bounds.size options:PSPDFCacheOptionDiskLoadSync|PSPDFCacheOptionRenderSkip|PSPDFCacheOptionMemoryStoreAlways];
            if (targetPageImage) {
                targetPageImageView = [[UIImageView alloc] initWithImage:targetPageImage];
                targetPageImageView.frame = self.magazineView.bounds;
                targetPageImageView.contentMode = UIViewContentModeScaleAspectFit;
                targetPageImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
                targetPageImageView.alpha = 0.f;
                [self.magazineView addSubview:targetPageImageView];
            }
        }

        [UIView animateWithDuration:0.3f delay:0.f options:0 animations:^{
            self.navigationController.navigationBar.alpha = 0.f;
            _shadowView.shadowEnabled = NO;
            self.collectionView.transform = CGAffineTransformMakeScale(0.97, 0.97);

            _animationDoubleWithPageCurl = pdfController.pageTransition == PSPDFPageCurlTransition && [pdfController isDoublePageMode];
            CGRect newFrame = [self magazinePageCoordinatesWithDoublePageCurl:_animationDoubleWithPageCurl];
            coverImageView.frame = newFrame;
            targetPageImageView.alpha = 1.f;

            self.collectionView.alpha = 0.0f;

        } completion:^(BOOL finished) {
            [self.navigationController.navigationBar.layer addAnimation:PSPDFFadeTransition() forKey:kCATransition];
            [self.navigationController pushViewController:pdfController animated:NO];

            cell.hidden = NO;
        }];
    }else {
        if (animated) {
            // Add fake data so that we animate back.
            _animateViewWillAppearWithFade = YES;
            [self.navigationController.view.layer addAnimation:PSPDFFadeTransition() forKey:kCATransition];
        }
        [self.navigationController pushViewController:pdfController animated:NO];
    }

    return YES;
}
*/


// Open magazine with a nice animation.
- (BOOL)openMagazine:(PSCMagazine *)magazine animated:(BOOL)animated cellIndex:(NSUInteger)cellIndex {
    self.lastOpenedMagazine = magazine;
    // [self.searchBar resignFirstResponder];
    magazine.overrideClassNames = @{(id)[PSPDFBookmarkParser class] : [PSCBookmarkParser class]};
    
    
    // Speed up displaying with parsing several things PSPDFViewController needs.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [magazine fillCache];
    });
    
    PSCKioskPDFViewController *pdfController = [[PSCKioskPDFViewController alloc] initWithDocument:magazine];
    
    
    // Try to get full-size image, if that fails try thumbnail.
    UIImage *coverImage = [self imageForMagazine:magazine];
    if (animated && coverImage && !magazine.isLocked) {
        PSUICollectionViewCell *cell = (PSUICollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:cellIndex inSection:0]];
        cell.hidden = YES;
        CGRect cellCoords = [self.collectionView convertRect:cell.frame toView:self.view];
        UIImageView *coverImageView = [[UIImageView alloc] initWithImage:coverImage];
        
        
        coverImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        coverImageView.frame = cellCoords;
        
        
        
        coverImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:coverImageView];
        self.magazineView = coverImageView;
        _animationCellIndex = cellIndex;
        
        // Add a smooth status bar transition on the iPhone
        if (!PSIsIpad()) {
            [UIApplication.sharedApplication setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
        }
        
        // If we have a different page, fade to that page.
        UIImageView *targetPageImageView = nil;
        if (pdfController.page != 0 && !pdfController.isDoublePageMode) {
            UIImage *targetPageImage = [PSPDFCache.sharedCache imageFromDocument:magazine andPage:pdfController.page withSize:UIScreen.mainScreen.bounds.size options:PSPDFCacheOptionDiskLoadSync|PSPDFCacheOptionRenderSkip|PSPDFCacheOptionMemoryStoreAlways];
            if (targetPageImage) {
                targetPageImageView = [[UIImageView alloc] initWithImage:targetPageImage];
                targetPageImageView.frame = self.magazineView.bounds;
                targetPageImageView.contentMode = UIViewContentModeScaleAspectFit;
                targetPageImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
                targetPageImageView.alpha = 0.f;
                [self.magazineView addSubview:targetPageImageView];
            }
        }
        
        [UIView animateWithDuration:0.3f delay:0.f options:0 animations:^{
            self.navigationController.navigationBar.alpha = 0.f;
            _shadowView.shadowEnabled = NO;
            self.collectionView.transform = CGAffineTransformMakeScale(0.97, 0.97);
            
            _animationDoubleWithPageCurl = pdfController.pageTransition == PSPDFPageCurlTransition && [pdfController isDoublePageMode];
            CGRect newFrame = [self magazinePageCoordinatesWithDoublePageCurl:_animationDoubleWithPageCurl];
            coverImageView.frame = newFrame;
            targetPageImageView.alpha = 1.f;
            
            self.collectionView.alpha = 0.0f;
            
        } completion:^(BOOL finished) {
            [self.navigationController.navigationBar.layer addAnimation:PSPDFFadeTransition() forKey:kCATransition];
            [self.navigationController pushViewController:pdfController animated:NO];
            
            cell.hidden = NO;
        }];
    }else {
        if (animated) {
            // Add fake data so that we animate back.
            _animateViewWillAppearWithFade = YES;
            [self.navigationController.view.layer addAnimation:PSPDFFadeTransition() forKey:kCATransition];
        }
        [self.navigationController pushViewController:pdfController animated:NO];
    }
    
    return YES;
}




- (void)diskDataLoaded {
    // Update indicator
    [self setProgressIndicatorVisible:PSCStoreManager.sharedStoreManager.isDiskDataLoaded animated:YES];

    // Not finished yet? return early.
    if ([[PSCStoreManager sharedStoreManager].magazineFolders count] == 0) return;

    // If we're in plain mode, pre-set a folder.
    if (kPSPDFStoreManagerPlain) self.magazineFolder = PSCStoreManager.sharedStoreManager.magazineFolders.lastObject;

    // Preload all magazines. (copy to prevent mutation errors)
    // Don't do this on old devices, might gobble up the render stack if there are slow documents.
    if (!PSPDFIsCrappyDevice()) {
        NSArray *magazines = [self.magazineFolder.magazines copy];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            for (PSCMagazine *magazine in magazines) {
                [PSPDFCache.sharedCache imageFromDocument:magazine andPage:0 withSize:kPSCLargeThumbnailSize options:PSPDFCacheOptionDiskLoadSkip|PSPDFCacheOptionRenderQueueBackground|PSPDFCacheOptionMemoryStoreNever|PSPDFCacheOptionActualityIgnore];
            }
        });
    }

    [self updateGrid];
}

- (BOOL)canEditCell:(PSCImageGridViewCell *)cell {
    BOOL editing = self.isEditing;
    if (editing) {
        if (cell.magazine) {
            editing =  cell.magazine.isDownloading || (cell.magazine.isAvailable && cell.magazine.isDeletable);
        }else {
            
            NSArray *fixedMagazines = [self.magazineFolder.magazines filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isDeletable = NO || isAvailable = NO || isDownloading = YES"]];
            editing = [fixedMagazines count] == 0;
        }
    }
    return YES;
}

- (void)updateEditingAnimated:(BOOL)animated {
    NSArray *visibleCells = [self.collectionView visibleCells];

    for (PSCImageGridViewCell *cell in visibleCells) {
        if ([cell isKindOfClass:[PSCImageGridViewCell class]]) {

            BOOL editing = [self canEditCell:cell];
            if (editing) cell.showDeleteImage = editing;
            cell.deleteButton.alpha = editing?0.f:1.f;

            [UIView animateWithDuration:0.3f delay:0.f options:UIViewAnimationOptionAllowUserInteraction animations:^{
                cell.deleteButton.alpha = editing?1.f:0.f;
            } completion:^(BOOL finished) {
                if (finished) {
                    cell.showDeleteImage = editing;
                }
            }];
        }
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self updateEditingAnimated:animated];
}

- (void)setEditing:(BOOL)editing {
    [super setEditing:editing];
    [self updateEditingAnimated:NO];
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.magazineFolder) {
        _filteredData = self.magazineFolder.magazines;
    }else {
        _filteredData = [PSCStoreManager sharedStoreManager].magazineFolders;
    }
    
    
//    if ([UIAPPDelegate isMyTopic]) {
//        self.markedMags = [NSMutableArray new];
//        NSArray *names = [self.markedTopics valueForKey:@"pdfName"];
//        //return [self.markedTopics count];
//        for (PSCMagazine * mag in _filteredData) {
//            if([names containsObject:mag.fileName] == YES ) {
//                [self.markedMags addObject:mag];
//            }
//        }
//        _filteredData=[self.markedMags copy];
//               
//    }
    
    NSString *searchString = _searchBar.text;
    if ([searchString length]) { // title CONTAINS[cd] '%@' ||
        NSString *predicate = [NSString stringWithFormat:@"fileURL.path CONTAINS[cd] '%@'", searchString];
        _filteredData = [_filteredData filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicate]];
    }
    

    
  //  else
        //_filteredData = [_filteredData copy];
         return [_filteredData count];
    //}
    
   

}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PSCImageGridViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([PSCImageGridViewCell class]) forIndexPath:indexPath];
    
    
   // connect the delete button
    if ([[cell.deleteButton allTargets] count] == 0){
        [cell.deleteButton addTarget:self action:@selector(processDeleteAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    cell.immediatelyLoadCellImages = self.immediatelyLoadCellImages;
    if (self.magazineFolder) {
        cell.magazine = _filteredData[indexPath.item];
    }else {
        cell.magazineFolder = _filteredData[indexPath.item];
    }
    cell.showDeleteImage = [self canEditCell:cell];
    cell.tag=indexPath.item;
    
    
    
   

if([cell.contentView subviews].count>0)
{
   //for (int i=0; i < [[cell.contentView subviews] count];i++) {
        
        UIButton *btn1=(UIButton *)[self.view viewWithTag:cell.tag+1000];
        UIButton *btn2=(UIButton *)[self.view viewWithTag:cell.tag+2000];
         UIButton *btn3=(UIButton *)[self.view viewWithTag:cell.tag+3000];
        if (btn1) {
            [btn1 removeFromSuperview];
            
        }
        if (btn2){
            
            [btn2 removeFromSuperview];
            
        }
    if (btn3){
        
        [btn3 removeFromSuperview];
        
    }
    
    
    
    //}
}
    
    
    
    if ([UIAPPDelegate isMyTopic]){
        
        
        self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressItem:)];
        [cell addGestureRecognizer:self.longPress];
        
        if (self.longPressed==YES) {
            UIButton *addButton=[[UIButton alloc] initWithFrame:CGRectMake(5, 5, 30, 30)];
            [addButton addTarget:self action:@selector(selectTopic:) forControlEvents:UIControlEventTouchDown];
            [addButton setImage:[UIImage imageNamed:@"circle-add.png"] forState:UIControlStateNormal];
            addButton.tag=cell.tag+1000;
            addButton.userInteractionEnabled=YES;
          ///  addButton.hidden=YES;
           addButton.hidden=NO;
        
            
            
            [cell.contentView addSubview:addButton];
            
             UIButton *removeButton=[[UIButton alloc] initWithFrame:CGRectMake(140, 5, 30, 30)];
            [removeButton setImage:[UIImage imageNamed:@"circle-remove.png"] forState:UIControlStateNormal];
            removeButton.tag=cell.tag+2000;
            [removeButton addTarget:self action:@selector(removeTopic:) forControlEvents:UIControlEventTouchDown];
            removeButton.hidden=YES;
            [cell.contentView addSubview:removeButton];
        }
        if (self.clearPressed==YES) {
            
        
            [cell removeGestureRecognizer:self.longPress];
            
        }

        
        }
    
    
             self.markedMags = [NSMutableArray new];
          
              PSCMagazine *mag=  [_filteredData objectAtIndex:indexPath.item];
                if([self.markedTopics containsObject:mag.fileName] == YES ) {
                    
                UIButton *bookmarkButton=[[UIButton alloc] initWithFrame:CGRectMake(5, 190, 30, 30)];
                    [bookmarkButton setImage:[UIImage imageNamed:@"bookmark1.png"] forState:UIControlStateNormal];
                    bookmarkButton.tag=cell.tag+3000;
                    [cell.contentView addSubview:bookmarkButton];
                    bookmarkButton.userInteractionEnabled=NO;
               }


return (UICollectionViewCell *)cell;
}

- (void)longPressItem:(UILongPressGestureRecognizer*)gesture  {
    if ( gesture.state == UIGestureRecognizerStateEnded ) {
        
        NSLog(@"cell tag==%d",gesture.view.tag) ;
        
        [PSCStoreManager sharedStoreManager].delegate = self;
        
        // Ensure everything is up to date (we could change magazines in other controllers)
        
        self.immediatelyLoadCellImages = YES;
        [self diskDataLoaded]; // also reloads the grid
        self.immediatelyLoadCellImages = NO;
        
        if (_animateViewWillAppearWithFade) {
            [self.navigationController.view.layer addAnimation:PSPDFFadeTransition() forKey:kCATransition];
            _animateViewWillAppearWithFade = NO;
        }
        
        [self setProgressIndicatorVisible:PSCStoreManager.sharedStoreManager.isDiskDataLoaded animated:NO];
        [self updateGrid];
        
    self.longPressed=YES;
        
     [self.tools setItems:[NSArray arrayWithObjects: self.spacer, self.segment, self.spacer, self.share,self.clear, self.spacer,self.titleLAbel,self.bigspacer,self.bookmark,self.spacer,self.setting,self.spacer,self.search,self.spacer,self.help ,nil] animated:NO];
      
        
             
    }
}

-(void)selectTopic:(UIButton * )Sender
{
    UIButton *addBtn=(UIButton *)Sender;
    NSInteger itemIndex=addBtn.tag-1000;
    if (addBtn.selected==NO)
    {
        [addBtn setImage:[UIImage imageNamed:@"pdf-correct.png"] forState:UIControlStateNormal];
        UIButton *removeBtn=(UIButton *)[self.view viewWithTag:addBtn.tag+1000];
        removeBtn.hidden=NO;
        NSString *fileName1= [_filteredData[itemIndex] fileName];
        [self.sharePdfArray addObject:fileName1];
    }
    
}
-(void)removeTopic:(UIButton * )Sender
{
    UIButton *removeBtn=(UIButton *)Sender;
    removeBtn.hidden=YES;
    NSInteger itemIndex=removeBtn.tag-2000;
    UIButton *addeBtn=(UIButton *)[self.view viewWithTag:removeBtn.tag-1000];
    addeBtn.userInteractionEnabled=YES;
    NSString *fileName1= [_filteredData[itemIndex] fileName];
    [self.sharePdfArray removeObject:fileName1];
[addeBtn setImage:[UIImage imageNamed:@"circle-add.png"] forState:UIControlStateNormal];
    
}

#pragma mark -
#pragma mark Compose Mail/SMS

// Displays an SMS composition interface inside the application.


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error  {
	NSString *message = @"";
	// Notifies users about errors associated with the interface
	switch (result) {
		case MFMailComposeResultCancelled:
			message = @"Mail: canceled";
			break;
		case MFMailComposeResultSaved:
			message = @"Mail: saved";
			break;
		case MFMailComposeResultSent:
			message = @"Mail: sent";
            
            [self.sharePdfArray removeAllObjects];
            self.longPressed=NO;
            //[PSCStoreManager sharedStoreManager].delegate = self;
            
            // Ensure everything is up to date (we could change magazines in other controllers)
            self.immediatelyLoadCellImages = YES;
            [self diskDataLoaded]; // also reloads the grid
            self.immediatelyLoadCellImages = NO;
            
            if (_animateViewWillAppearWithFade) {
                [self.navigationController.view.layer addAnimation:PSPDFFadeTransition() forKey:kCATransition];
                _animateViewWillAppearWithFade = NO;
            }
            
            [self setProgressIndicatorVisible:PSCStoreManager.sharedStoreManager.isDiskDataLoaded animated:NO];

            [self updateGrid];
            [self changeButtonsOnTabChange:1];

			break;
		case MFMailComposeResultFailed:
			message = @"Mail: failed";
			break;
		default:
			message = @"Mail: not sent";
			break;
	}
    [self dismissViewControllerAnimated:YES completion:nil];
    
}


- (void)processDeleteAction:(UIButton *)button {
    [self processDeleteActionForCell:(PSCImageGridViewCell *)button.superview.superview];
}

- (void)processDeleteActionForCell:(PSCImageGridViewCell *)cell {
    PSCMagazine *magazine = cell.magazine;
    PSCMagazineFolder *folder = cell.magazineFolder;

    BOOL canDelete = YES;
    NSString *message = nil;
    if ([folder.magazines count] > 1 && !self.magazineFolder) {
        message = [NSString stringWithFormat:_(@"DeleteMagazineMultiple"), folder.title, [folder.magazines count]];
    }else {
        message = [NSString stringWithFormat:_(@"DeleteMagazineSingle"), magazine.title];
        if (kPSPDFShouldShowDeleteConfirmationDialog) {
            canDelete = magazine.isAvailable || magazine.isDownloading;
        }
    }

    dispatch_block_t deleteBlock = ^{
        if (self.magazineFolder) {
            if (magazine.isDownloading) {
                [[PSCStoreManager sharedStoreManager] cancelDownloadForMagazine:magazine];
            }else {
                [[PSCStoreManager sharedStoreManager] deleteMagazine:magazine];
            }
        }else {
            [[PSCStoreManager sharedStoreManager] deleteMagazineFolder:folder];
        }
    };

    if (kPSPDFShouldShowDeleteConfirmationDialog) {
        if (canDelete) {
            PSPDFActionSheet *deleteAction = [[PSPDFActionSheet alloc] initWithTitle:message];
            deleteAction.actionSheetStyle = UIActionSheetStyleBlackOpaque;
            [deleteAction setDestructiveButtonWithTitle:_(@"Delete") block:^{
                deleteBlock();
            }];
            [deleteAction setCancelButtonWithTitle:_(@"Cancel") block:nil];
            CGRect cellFrame = [cell convertRect:cell.imageView.frame toView:self.view];
            [deleteAction showFromRect:cellFrame inView:self.view animated:YES];
        }
    }else {
        deleteBlock();
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return PSIsIpad() ? kPSCLargeThumbnailSize : CGSizeMake(82, 130);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
  //  NSLog(@"sanjeev");
    if (self.longPressed==NO) {

    PSCMagazine *magazine;
    PSCMagazineFolder *folder;

    if (self.magazineFolder) {
        folder = self.magazineFolder;
        magazine = (_filteredData)[indexPath.item];
    }else {
        folder = (_filteredData)[indexPath.item];
        magazine = [folder firstMagazine];
    }

    PSCLog(@"Magazine selected: %d %@", indexPath.item, magazine);

    if (folder.magazines.count == 1 || self.magazineFolder) {
        if (magazine.isDownloading) {
            [[[UIAlertView alloc] initWithTitle:PSPDFAppName()
                                        message:_(@"Item is currently downloading.")
                                       delegate:nil
                              cancelButtonTitle:_(@"OK")
                              otherButtonTitles:nil] show];
        } else if (!magazine.isAvailable && !magazine.isDownloading) {
            if (!self.isEditing) {
                [[PSCStoreManager sharedStoreManager] downloadMagazine:magazine];
            }
        } else {
            [self openMagazine:magazine animated:YES cellIndex:indexPath.item];
        }
    }else {
        PSCGridController *gridController = [[PSCGridController alloc] initWithMagazineFolder:folder];

        
        
        
            // A full-page-fade animation doesn't work very well on iPad. (under a ux aspect; technically it's fine)
            if (!PSIsIpad()) {
                CATransition *transition = PSPDFFadeTransitionWithDuration(0.3f);
                [self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
                [self.navigationController pushViewController:gridController animated:NO];
                
            }else {
                [self.navigationController pushViewController:gridController animated:YES];
            }

            
        }
       

           
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // resign keyboard if we scroll down
    if (self.collectionView.contentOffset.y > 0) {
        [self.searchBar resignFirstResponder];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PSPDFStoreManagerDelegate

- (BOOL)isSearchModeActive {
   return self.searchBar.text.length > 0;
}

- (void)magazineStoreBeginUpdate {}
- (void)magazineStoreEndUpdate {}

- (void)magazineStoreFolderDeleted:(PSCMagazineFolder *)magazineFolder {
    if (self.isSearchModeActive) return; // don't animate if we're in search mode

    if (!self.magazineFolder) {
        NSUInteger cellIndex = [[PSCStoreManager sharedStoreManager].magazineFolders indexOfObject:magazineFolder];
        if (cellIndex != NSNotFound) {
            [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:cellIndex inSection:0]]];
        }else {
            PSCLog(@"index not found for %@", magazineFolder);
        }
    }
}

- (void)magazineStoreFolderAdded:(PSCMagazineFolder *)magazineFolder {
    if (self.isSearchModeActive) return; // don't animate if we're in search mode

    if (!self.magazineFolder) {
        NSUInteger cellIndex = [[PSCStoreManager sharedStoreManager].magazineFolders indexOfObject:magazineFolder];
        if (cellIndex != NSNotFound) {
            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:cellIndex inSection:0]]];
        }else {
            PSCLog(@"index not found for %@", magazineFolder);
        }
    }
}

- (void)magazineStoreFolderModified:(PSCMagazineFolder *)magazineFolder {
    if (self.isSearchModeActive) return; // don't animate if we're in search mode

    if (!self.magazineFolder) {
        NSUInteger cellIndex = [[PSCStoreManager sharedStoreManager].magazineFolders indexOfObject:magazineFolder];
        if (cellIndex != NSNotFound) {
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:cellIndex inSection:0]]];
        }else {
            PSCLog(@"index not found for %@", magazineFolder);
        }
    }
}

- (void)openMagazine:(PSCMagazine *)magazine {
    NSUInteger cellIndex = [self.magazineFolder.magazines indexOfObject:magazine];
    if (cellIndex != NSNotFound) {
        [self openMagazine:magazine animated:YES cellIndex:cellIndex];
    }else {
        PSCLog(@"index not found for %@", magazine);
    }
}

- (void)magazineStoreMagazineDeleted:(PSCMagazine *)magazine {
    if (self.isSearchModeActive) return; // don't animate if we're in search mode

    if (PSPDFIsCrappyDevice()) {
        [self.collectionView reloadData];
        return;
    }

    if (self.magazineFolder) {
        NSUInteger cellIndex = [self.magazineFolder.magazines indexOfObject:magazine];
        if (cellIndex != NSNotFound) {
            [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:cellIndex inSection:0]]];
        }else {
            PSCLog(@"index not found for %@", magazine);
        }
    }
}

- (void)magazineStoreMagazineAdded:(PSCMagazine *)magazine {
    if (self.isSearchModeActive) return; // don't animate if we're in search mode

    if (PSPDFIsCrappyDevice()) {
        [self.collectionView reloadData];
        return;
    }

    if (self.magazineFolder) {
        NSUInteger cellIndex = [self.magazineFolder.magazines indexOfObject:magazine];
        if (cellIndex != NSNotFound) {
            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:cellIndex inSection:0]]];
        }else {
            PSCLog(@"index not found for %@", magazine);
        }
    }
}

- (void)magazineStoreMagazineModified:(PSCMagazine *)magazine {
    if (self.isSearchModeActive) return; // don't animate if we're in search mode

    if (PSPDFIsCrappyDevice()) {
        [self.collectionView reloadData];
        return;
    }

    if (self.magazineFolder) {
        NSUInteger cellIndex = [self.magazineFolder.magazines indexOfObject:magazine];
        if (cellIndex != NSNotFound) {
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:cellIndex inSection:0]]];
        }else {
            PSCLog(@"index not found for %@", magazine);
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        searchBar.alpha = 1.f;
    } completion:NULL];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        searchBar.alpha = 0.5f;
    } completion:NULL];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    for (int i=0; i<[_filteredData count]; i++) {
        PSUICollectionViewCell *cell = (PSUICollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
        
        if([cell.contentView subviews].count>0)
            
            {
                
               for (int i=0; i < [[cell.contentView subviews] count];i++) {
                
                UIButton *btn1=(UIButton *)[self.view viewWithTag:cell.tag+1000];
                UIButton *btn2=(UIButton *)[self.view viewWithTag:cell.tag+2000];
                if (btn1) {
                    [btn1 removeFromSuperview];
                    }
                if (btn2){
                    [btn2 removeFromSuperview];
                    
                }
              }
            }
      }
    _filteredData = nil;
    [self updateGrid];
    self.collectionView.contentOffset = CGPointMake(0, -self.collectionView.contentInset.top);
    
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

@end

// Fixes the missing action method crash on updating when the keyboard is visible.
#import <objc/runtime.h>
#import <objc/message.h>
__attribute__((constructor)) static void PSPDFFixCollectionViewUpdateItemWhenKeyboardIsDisplayed(void) {
    PSPDF_IF_PRE_IOS6(return;) // stop if we're on iOS5.
    @autoreleasepool {
        if (![UICollectionViewUpdateItem instancesRespondToSelector:@selector(action)]) {
            IMP updateIMP = imp_implementationWithBlock(^(id _self) {});
            Method method = class_getInstanceMethod([UICollectionViewUpdateItem class], @selector(action));
            const char *encoding = method_getTypeEncoding(method);
            if (!class_addMethod([UICollectionViewUpdateItem class], @selector(action), updateIMP, encoding)) {
                PSPDFLogError(@"Failed to add action: workaround");
            }
        }
    }
}

