//
//  PSCKioskPDFViewController.h
//  PSPDFCatalog
//
//  Copyright 2011-2013 Peter Steinberger. All rights reserved.
//
#import "PSCBookmarkParser.h"
#import "SharePopoverView.h"
#import "MBProgressHUD.h"

@class MBProgressHUD;
@class PSCMagazine;

/// Customized subclass of PSPDFViewController, adding more HUD buttons.
@interface PSCKioskPDFViewController : PSPDFViewController <PSPDFViewControllerDelegate,PSPDFDocumentDelegate>
{
    
    UITextField *textfield;
    
      
      
}
@property(nonatomic,assign)BOOL isShare;
@property(nonatomic,assign)BOOL isSaveasDialogonShare;

@property(nonatomic,strong) NSString *documentFileName;
/// Referenced magazine; just a cast to .document.
@property (nonatomic, strong, readonly) PSCMagazine *magazine;
@property (nonatomic, strong) PSCBookmarkParser *pscBookmarkParser;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property(nonatomic,strong)UIBarButtonItem *shareBarbuttonItem;


@property(nonatomic,strong)SharePopoverView *sharePopover;
@property(nonatomic,assign) BOOL isSelectedMyTopics;
@property(nonatomic,assign) BOOL isShared;

@end
