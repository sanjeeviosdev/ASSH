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
#import "ListPopoverViewController.h"
#import "OpenLinkViewController.h"



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
                                             selector:@selector(selectMagazine:)
                                                 name:@"selectTopic"
                                               object:nil];

    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadGrid)
                                                 name:@"reloadGrid"
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
    
    
    //listButton
    
    UIButton *listBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *listBtnImage = [UIImage imageNamed:@"listview.png"];
    [listBtn setBackgroundImage:listBtnImage forState:UIControlStateNormal];
    [listBtn addTarget:self action:@selector(listAction) forControlEvents:UIControlEventTouchUpInside];
    [listBtn setFrame:CGRectMake(0, 0, 30, 31)];
    self.list = [[UIBarButtonItem alloc] initWithCustomView:listBtn];
    
    // Create a segment control
    
    UISegmentedControl *seg1 = [[UISegmentedControl alloc]
                                initWithItems:[NSArray arrayWithObjects:@"Topics", @"My Topics", nil]];
    [seg1 addTarget:self action:@selector(onSegmentChanged:) forControlEvents:UIControlEventValueChanged];
    seg1.selectedSegmentIndex=0;
    seg1.frame=CGRectMake(0, 0, 200, 30);
    seg1.tintColor=[UIColor colorWithRed:0.847 green:0.9255 blue:0.9725 alpha:1];
     self.segment = [[UIBarButtonItem alloc] initWithCustomView:seg1];
    
   
    self.biggerSpacer = [[UIBarButtonItem alloc]
                         initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                         target:nil
                         action:nil];
    self.biggerSpacer.width=200;
    
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
    [shareBtn setFrame:CGRectMake(0, 0, 30, 30)];
    self.share = [[UIBarButtonItem alloc] initWithCustomView:shareBtn];
    
    UIButton *settingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backBtnImage = [UIImage imageNamed:@"settings.png"];
    [settingBtn setBackgroundImage:backBtnImage forState:UIControlStateNormal];
    [settingBtn addTarget:self action:@selector(settingAction) forControlEvents:UIControlEventTouchUpInside];
    settingBtn.frame = CGRectMake(0, 0, 38, 27);
    self.setting = [[UIBarButtonItem alloc] initWithCustomView:settingBtn];

    
    UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *clearBtnImage = [UIImage imageNamed:@"clear.png"];
    
    [clearBtn setBackgroundImage:clearBtnImage forState:UIControlStateNormal];
    [clearBtn addTarget:self action:@selector(clearAction) forControlEvents:UIControlEventTouchUpInside];
    clearBtn.frame = CGRectMake(0, 0, 30, 30);
    //[tools addSubview:contentBtn];
    self.clear = [[UIBarButtonItem alloc] initWithCustomView:clearBtn];
    //[buttons addObject:content];
    
    UIButton *bookmarkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *bookmarkBtnImage = [UIImage imageNamed:@"bookmark.png"];
    [bookmarkBtn setBackgroundImage:bookmarkBtnImage forState:UIControlStateNormal];
    [bookmarkBtn addTarget:self action:@selector(bookmarkAction) forControlEvents:UIControlEventTouchUpInside];
    bookmarkBtn.frame = CGRectMake(0, 0, 32,27 );
    self.bookmark = [[UIBarButtonItem alloc] initWithCustomView:bookmarkBtn];
    
    
    self.searchBar=[[UISearchBar alloc] init];
    [self.searchBar setFrame:CGRectMake(775,10,220,25)];
    self.searchBar.delegate=self;
    self.searchBar.userInteractionEnabled=YES;
     self.search = [[UIBarButtonItem alloc] initWithCustomView:self.searchBar];
    
    UIButton *helpBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *helpBtnImage = [UIImage imageNamed:@"help.png"];
    helpBtn.userInteractionEnabled=YES;

    //[helpBtn setBackgroundImage:helpBtnImage forState:UIControlStateNormal];
    [helpBtn setImage:helpBtnImage forState:UIControlStateNormal];
    [helpBtn addTarget:self action:@selector(helpBtnAction) forControlEvents:UIControlEventTouchUpInside];
    helpBtn.frame = CGRectMake(0, 0, 32, 32);
    self.help = [[UIBarButtonItem alloc] initWithCustomView:helpBtn];
    
    [self.tools setItems:[NSArray arrayWithObjects: self.segment, self.spacer,self.list,self.spacer, self.share,self.spacer,self.bigspacer,self.bigspacer,self.biggerSpacer,self.bigspacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
    
  UIBarButtonItem *custom = [[UIBarButtonItem alloc] initWithCustomView:self.tools];
    
    self.navigationItem.leftBarButtonItem = custom;
    
    //self.navigationController.navigationBar.tintColor=[UIColor colorWithRed:0.847 green:0.9255 blue:0.9725 alpha:1];
    
    self.navigationController.navigationBar.tintColor=[UIColor lightGrayColor];

    [self changeButtonsOnTabChange:0];
    
#ifdef PSPDFCatalog

#endif

    //Add global shadow.
    CGFloat toolbarHeight = self.navigationController.navigationBar.frame.size.height;
    self.shadowView = [[PSCShadowView alloc] initWithFrame:CGRectMake(0, -toolbarHeight, self.view.bounds.size.width, toolbarHeight)];
    _shadowView.shadowOffset = toolbarHeight;
    _shadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _shadowView.backgroundColor = [UIColor clearColor];
    _shadowView.userInteractionEnabled = NO;
    [self.view addSubview:_shadowView];

    // Use custom view to match background with PSPDFViewController.
    UIView *backgroundTextureView = [[UIView alloc] initWithFrame:CGRectMake(0, -toolbarHeight, self.view.bounds.size.width, self.view.bounds.size.height)];
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
    
    
    // adding the bottom toolbar
      self.bottomToolbar=[[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-85, self.view.frame.size.width,44)];
    [self.view addSubview:self.bottomToolbar];
    self.bottomToolbar.tintColor=[UIColor lightGrayColor];
    self.linkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
   // UIImage *linkBtnImage = [UIImage imageNamed:@"top bar.png"];
     //UIImage *linkBtnImage = [UIImage imageNamed:@"footerlogo.png"];
    //[self.linkButton setBackgroundImage:linkBtnImage forState:UIControlStateNormal];
    [self.linkButton setTitle:@"Tap to Find a Hand Surgeon in your area." forState:UIControlStateNormal];
    [self.linkButton addTarget:self action:@selector(openLinkAction:) forControlEvents:UIControlEventTouchUpInside];
    self.linkButton.tag=90000;
    self.linkButton.frame = CGRectMake(0, 0, 350, 44);
    self.link = [[UIBarButtonItem alloc] initWithCustomView:self.linkButton];
    self.logoButton=[[UIButton alloc] init];
    
    UIImage *logoImage = [UIImage imageNamed:@"logoImage.png"];
    [self.logoButton setImage:logoImage forState:UIControlStateNormal];
    [self.logoButton setFrame:CGRectMake(0,0, 112, 40)];
    
    [self.logoButton addTarget:self action:@selector(openLinkAction:) forControlEvents:UIControlEventTouchUpInside];
     self.logo = [[UIBarButtonItem alloc] initWithCustomView:self.logoButton];
    
   
     UIButton *sitelinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
     [sitelinkButton setTitle:@"www.handcare.org" forState:UIControlStateNormal];
    [sitelinkButton addTarget:self action:@selector(openLinkAction:) forControlEvents:UIControlEventTouchUpInside];
    sitelinkButton.tag=90001;
    sitelinkButton.frame = CGRectMake(0, 0, 350, 44);
    self.siteLink = [[UIBarButtonItem alloc] initWithCustomView:sitelinkButton];
    [self.bottomToolbar setItems:[NSArray arrayWithObjects: self.link,self.logo,self.siteLink, nil]];



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


-(void)openLinkAction:(id)Sender

{
    UIButton *btn=(UIButton *)Sender;
    OpenLinkViewController *openLink=[[OpenLinkViewController alloc] initWithNibName:@"OpenLinkViewController" bundle:nil];
    if(btn.tag==90001)
    {
        openLink.urlStr=@"http://www.handcare.org";
 
    }
    else
        openLink.urlStr=@"http://www.assh.org/Public/Pages/HandSurgeons.aspx";

    
    [self.navigationController pushViewController:openLink animated:YES];
}

- (void) changeButtonsOnTabChange:(int) tabId{
    if (tabId == 0) {
        
        if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
            //other codes
            [self.tools setItems:[NSArray arrayWithObjects: self.segment,self.list,self.spacer,self.spacer, self.bigspacer, self.bigspacer,self.bigspacer,self.spacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
        }
        
        else {
            
                       [self.tools setItems:[NSArray arrayWithObjects: self.segment,self.spacer,self.list,self.spacer,self.spacer, self.bigspacer, self.bigspacer,self.bigspacer,self.spacer,self.biggerSpacer,self.bigspacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
            //other codes
        }
        
    } else {
        
        
        if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
            //other codes
            
             if (self.longPressed==YES)
             {
                 [self.tools setItems:[NSArray arrayWithObjects: self.segment, self.list,self.spacer,  self.share, self.clear,self.bigspacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
             }
            else
            {
            [self.tools setItems:[NSArray arrayWithObjects: self.segment,self.list,self.spacer,  self.share, self.spacer,self.spacer,self.bigspacer,self.bigspacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
            }
            
        }
        
        else {
            if (self.longPressed==YES) {
                [self.tools setItems:[NSArray arrayWithObjects: self.segment,self.list,self.spacer,  self.share, self.clear,self.bigspacer,self.biggerSpacer,self.bigspacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];

                
            }
            else

            [self.tools setItems:[NSArray arrayWithObjects: self.segment, self.spacer,self.list,self.spacer,  self.share, self.spacer,self.spacer,self.bigspacer,self.bigspacer,self.biggerSpacer,self.bigspacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
            //other codes
        }
        
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
-(void)listAction
    {
        if(![popoverController isPopoverVisible]){
            self.listPopover = [[ListPopoverViewController alloc] initWithNibName:@"ListPopoverViewController" bundle:nil];
            self.listPopover.topicsArray=_filteredData;
            popoverController = [[UIPopoverController alloc] initWithContentViewController:self.listPopover];
            //[popoverController setDelegate:self];
            int arrCount=[_filteredData count];
            int height= arrCount*44;
            float popoverheight=(float)height;
            
            if (arrCount==0) {
                 [popoverController setPopoverContentSize:CGSizeMake(360.0f, 200)];
            }
            else
               [popoverController setPopoverContentSize:CGSizeMake(360.0f, popoverheight)];
            if (self.view.window != nil)
            {
        
                 if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
            
                [popoverController presentPopoverFromRect:CGRectMake(175, -105, 111, 111) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
                 }
            else
            {
                [popoverController presentPopoverFromRect:CGRectMake(185, -105, 111, 111) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
            }
            }
                
            
        }else {
            [popoverController dismissPopoverAnimated:YES];
            popoverController.delegate=nil;
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
            if([mailBody isEqualToString:@""]||mailBody==nil||[mailBody isEqualToString:@"(null)"])
            {
                mailBody=@"HandCare";
            }
            if([mailSignature isEqualToString:@""]||mailSignature==nil||[mailSignature isEqualToString:@"(null)"])
                   
            {
                mailSignature=@"";
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
        UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"Share" message:@"Use this icon to attach multiple topics to the same email. Tap and hold a tile to get the + symbol on each, select the topics for sharing and tap this icon again to send." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alert show];
    }


}
-(void)clearAction
{
    self.longPressed=NO;
    self.clearPressed=YES;
    [self.sharePdfArray removeAllObjects];
     if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
         
           [self.tools setItems:[NSArray arrayWithObjects:self.segment,self.list,self.spacer, self.share, self.spacer,self.spacer,self.bigspacer,self.bigspacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
         }
         else
         {
    
          [self.tools setItems:[NSArray arrayWithObjects:self.segment, self.spacer,self.list,self.spacer, self.share, self.spacer,self.spacer,self.bigspacer,self.bigspacer, self.biggerSpacer,self.bigspacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
             
         }
     
   
    
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
        {
            
            if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
            {
                [popoverController presentPopoverFromRect:CGRectMake(365, -105, 111, 111) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
            }
                 else
                 {
            [popoverController presentPopoverFromRect:CGRectMake(615, -105, 111, 111) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
                 }
        }
        
    }else {
        [popoverController dismissPopoverAnimated:YES];
        popoverController.delegate=nil;
    }
    

    
    
}
-(void)helpBtnAction
{
    if(![popoverController isPopoverVisible]){
    helpPopOver = [[HelpPopoverController alloc] initWithNibName:@"HelpPopoverController" bundle:nil];
    popoverController = [[UIPopoverController alloc] initWithContentViewController:helpPopOver];
    //[popoverController setDelegate:self];
    if (self.view.window != nil)
    {
        
        if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
        {
            [popoverController setPopoverContentSize:CGSizeMake(577.0f, 700.0f)];

        [popoverController presentPopoverFromRect:CGRectMake(750, -105, 111, 111) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        }
        else
        {
            [popoverController setPopoverContentSize:CGSizeMake(700.0f, 558.0f)];

          [popoverController presentPopoverFromRect:CGRectMake(1000, -105, 111, 111) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        }
    }
    
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
            
        {
            
            if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
            {
            [popoverController presentPopoverFromRect:CGRectMake(405, -105, 111, 111) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
            }
            else
            {
                [popoverController presentPopoverFromRect:CGRectMake(655, -105, 111, 111) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
            }
        }
		
	}else{
		[popoverController dismissPopoverAnimated:YES];
        popoverController.delegate=nil;
	}

}
-(void)cancel
{
    [popoverController dismissPopoverAnimated:YES];
 
}
-(void)reloadGrid
{
    
    self.markedTopics = [UIAPPDelegate fetchBookmarks];
    [popoverController dismissPopoverAnimated:YES];
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

- (void)selectBookmarkedBook:(NSNotification *)notif {
    [popoverController dismissPopoverAnimated:YES];

    PSCMagazine *mag=(PSCMagazine *)[notif object];
    [self openMagazine:mag];
    
    
}
- (void)selectMagazine:(NSNotification *)notif {
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
        
        self.markedTopics = [UIAPPDelegate fetchBookmarks];

        
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
        
        self.markedTopics = [UIAPPDelegate fetchBookmarks];

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
    
     [self updateNavBar];
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
    [self updateGrid];
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




// Open magazine with a nice animation.
- (BOOL)openMagazine:(PSCMagazine *)magazine animated:(BOOL)animated cellIndex:(NSUInteger)cellIndex {
    
   
    self.lastOpenedMagazine = magazine;
     [self.searchBar resignFirstResponder];
    magazine.overrideClassNames = @{(id)[PSPDFBookmarkParser class] : [PSCBookmarkParser class]};
    
    
    // Speed up displaying with parsing several things PSPDFViewController needs.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [magazine fillCache];
    });
    
    PSCKioskPDFViewController *pdfController = [[PSCKioskPDFViewController alloc] initWithDocument:magazine];
    
    
   pdfController.outlineButtonItem.availableControllerOptions = [NSOrderedSet orderedSetWithObjects: @(PSPDFOutlineBarButtonItemOptionAnnotations), nil];
    
        
    /*
    
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
     }
     */
        [self.navigationController pushViewController:pdfController animated:NO];

     
    
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
        if (cell.magazine)
        {
            
            editing =  cell.magazine.isDownloading || (cell.magazine.isAvailable && cell.magazine.isDeletable);
        }
        else
        {
            
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
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"UID" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObject: sorter];
    _filteredData = [_filteredData sortedArrayUsingDescriptors:sortDescriptors];
    

    
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
    
    for (UIView *subview in [cell.contentView subviews]) {
        if (subview.tag >= 3000) {
            [subview removeFromSuperview];
        }
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
            
        
              
            //[cell removeGestureRecognizer:self.longPress];
            
        }

        
        
        }
    else
    {
       [cell removeGestureRecognizer:self.longPress]; 
    }
    
    
    self.markedMags = [NSMutableArray new];
    
    PSCMagazine *mag=  [_filteredData objectAtIndex:indexPath.item];
    if([self.markedTopics containsObject:mag.fileName] == YES ) {
        //if ([mag.bookmarks count]>0)
        //{
        if (mag.bookmarksEnabled==YES) {
            
            
            UIButton *bookmarkButton=[[UIButton alloc] initWithFrame:CGRectMake(5, 190, 30, 30)];
            [bookmarkButton setImage:[UIImage imageNamed:@"bookmark2.png"] forState:UIControlStateNormal];
            bookmarkButton.tag=cell.tag + 3000;
            [cell.contentView addSubview:bookmarkButton];
            bookmarkButton.userInteractionEnabled=NO;
        }
       // }
    }
return (UICollectionViewCell *)cell;
    
}

- (void)longPressItem:(UILongPressGestureRecognizer*)gesture  {
    if ( gesture.state == UIGestureRecognizerStateEnded ) {
        
        if ([UIAPPDelegate isMyTopic]){

        
        NSLog(@"cell tag==%d",gesture.view.tag) ;
        
        [PSCStoreManager sharedStoreManager].delegate = self;
        
        // Ensure everything is up to date (we could change magazines in other controllers)
        
        self.immediatelyLoadCellImages = YES;
        [self diskDataLoaded];
          // also reloads the grid
        self.immediatelyLoadCellImages = NO;
        
        if (_animateViewWillAppearWithFade) {
            [self.navigationController.view.layer addAnimation:PSPDFFadeTransition() forKey:kCATransition];
            _animateViewWillAppearWithFade = NO;
        }
        
        [self setProgressIndicatorVisible:PSCStoreManager.sharedStoreManager.isDiskDataLoaded animated:NO];
        [self updateGrid];
        
    self.longPressed=YES;
            
         if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
         {
              [self.tools setItems:[NSArray arrayWithObjects: self.segment,self.list,self.spacer, self.share,self.clear,self.bigspacer,self.spacer,self.spacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
             
         }
         else{
        
     [self.tools setItems:[NSArray arrayWithObjects: self.segment, self.spacer,self.list,self.spacer, self.share,self.clear,self.bigspacer,self.bigspacer, self.biggerSpacer,self.spacer,self.spacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
         }
      
        }
             
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
        if ([self.sharePdfArray containsObject:fileName1] == NO) {
            [self.sharePdfArray addObject:fileName1];
        }
    
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
            [ self clearAction];
                    break;
		case MFMailComposeResultFailed:
			message = @"Mail: failed";
            [self.sharePdfArray removeAllObjects];
            [ self clearAction];
			break;
		default:
			message = @"Mail: not sent";
            [self.sharePdfArray removeAllObjects];
            [ self clearAction];
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
    
    if ([UIAPPDelegate isMyTopic]==NO) {
        
        {
            
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
    else{
    
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

- (void)magazineStoreMagazineAdded:(PSCMagazine *)magazine
{
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


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [ self orientation];
    [self updateNavBar];

    return YES;
}

- (BOOL)shouldAutorotate  // iOS 6 autorotation fix
{
    
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations // iOS 6 autorotation fix
{
    [ self orientation];
    [self updateNavBar];

    return UIInterfaceOrientationMaskAll;
}


- (void) updateNavBar {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if ((UIInterfaceOrientationLandscapeLeft == orientation) ||
        (UIInterfaceOrientationLandscapeRight == orientation)) {
        self.navigationController.navigationBar.frame = CGRectMake(0, 20, 1024, 44);
        [self.tools setFrame:CGRectMake(0, 0, 1024, 44)];
        [self.bottomToolbar setItems:[NSArray arrayWithObjects: self.link,self.bigspacer,self.bigspacer, self.logo,self.bigspacer,self.siteLink, nil]];
        self.bottomToolbar.frame=CGRectMake(0, self.view.frame.size.height-44, self.view.frame.size.width,44);


    } else {
        self.navigationController.navigationBar.frame = CGRectMake(0, 20, 768, 44);
        [self.tools setFrame:CGRectMake(0, 0, 768, 44)];
        [self.bottomToolbar setItems:[NSArray arrayWithObjects: self.link,self.logo,self.spacer,self.siteLink, nil]];
        self.bottomToolbar.frame=CGRectMake(0, self.view.frame.size.height-44, self.view.frame.size.width,44);



    }
}


-(void)orientation
{
    [popoverController dismissPopoverAnimated:YES];
    popoverController.delegate=nil;

    if (![UIAPPDelegate isMyTopic]) {
    
    if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        //other codes
        [self.tools setItems:[NSArray arrayWithObjects: self.segment,self.list,self.spacer,self.spacer,self.spacer, self.bigspacer, self.bigspacer,self.bigspacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
        
        
    }
    
    else {
        [self.tools setItems:[NSArray arrayWithObjects: self.segment,self.spacer,self.list,self.spacer,self.spacer, self.bigspacer, self.bigspacer,self.bigspacer,self.spacer,self.biggerSpacer,self.bigspacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
        //other codes
    }
    
} else {
    if (self.longPressed==YES) {
        if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
            //other codes
            [self.tools setItems:[NSArray arrayWithObjects: self.segment,self.list,self.spacer,  self.share, self.clear,self.spacer,self.spacer,self.bigspacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
            
        }
        
        else {
            [self.tools setItems:[NSArray arrayWithObjects:  self.segment, self.spacer,self.list,self.spacer,  self.share, self.spacer,self.spacer,self.clear,self.spacer,self.spacer,self.spacer,self.spacer,self.biggerSpacer,self.bigspacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
            //other codes
        }
    }
    else{
        
    if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        //other codes
        [self.tools setItems:[NSArray arrayWithObjects: self.segment,self.list,self.spacer,  self.share, self.spacer,self.spacer,self.bigspacer,self.bigspacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
        
    }
    
    else {
        [self.tools setItems:[NSArray arrayWithObjects: self.segment, self.spacer,self.list,self.spacer,  self.share, self.spacer,self.spacer,self.bigspacer,self.bigspacer,self.biggerSpacer,self.bigspacer,self.bookmark,self.setting,self.search,self.help ,nil] animated:NO];
        //other codes
    }
    }
}
    
     self.bottomToolbar.frame=CGRectMake(0, self.view.frame.size.height-44, self.view.frame.size.width,44);
    self.linkButton.frame = CGRectMake(0, 0, 350, 44);

    


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


