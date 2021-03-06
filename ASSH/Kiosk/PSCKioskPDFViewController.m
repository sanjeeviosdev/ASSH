//  PSCKioskPDFViewController.m
//  PSPDFCatalog
//
//Copyright 2011-2013 Peter Steinberger. All rights reserved.
//

#import "PSCKioskPDFViewController.h"
#import "PSCMagazine.h"
#import "PSCSettingsController.h"
#import "PSCGridController.h"
#import "PSCSettingsBarButtonItem.h"
#import "ASSHAppDelegate.h"
#ifdef PSPDFCatalog
#import "PSCAnnotationTableBarButtonItem.h"
#import "PSCGoToPageButtonItem.h"
#import "PSCMetadataBarButtonItem.h"
#import "PSCCustomBookmarkBarButtonItem.h"


#endif

#if !__has_feature(objc_arc)
#error "Compile this file with ARC"
#endif

@interface PSCKioskPDFViewController () {
    BOOL _hasLoadedLastPage;
    UIBarButtonItem *_closeButtonItem;
    PSCSettingsBarButtonItem *_settingsButtomItem;
    
#ifdef PSPDFCatalog
    PSCMetadataBarButtonItem *_metadataButtonItem;
    PSCAnnotationTableBarButtonItem *_annotationListButtonItem;
#endif
}
- (void) showSaveAsDialog;
@end

@implementation PSCKioskPDFViewController

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)initWithDocument:(PSPDFDocument *)document {
    if ((self = [super initWithDocument:document])) {
        self.delegate = self;

        document.delegate = self;
        self.pscBookmarkParser=[[PSCBookmarkParser alloc]initWithDocument:document];
        
       // Initially update vars.
        [self globalVarChanged];
        
        [self setToolbarEnabled:NO];
        self.statusBarStyleSetting = PSPDFStatusBarBlackOpaque;
        self.renderAnimationEnabled = NO; // custom implementation here
        self.fitToWidthEnabled=YES;

             
        // Register for global var change notifications from PSPDFCacheSettingsController.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(globalVarChanged) name:kGlobalVarChangeNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(shareBtn:)
                                                    name:@"sharepopover"
                                                        object:nil];
        
               
        //remove some options from annotation toolbar
        NSMutableOrderedSet *editableTypes = [document.editableAnnotationTypes mutableCopy];
        [editableTypes removeAllObjects];
        [editableTypes addObject:PSPDFAnnotationTypeStringNote];
        [editableTypes addObject:PSPDFAnnotationTypeStringInk];
        [editableTypes addObject:PSPDFAnnotationTypeStringHighlight];
        [editableTypes addObject:PSPDFAnnotationTypeStringUnderline];
        [editableTypes addObject:PSPDFAnnotationTypeStringStrikeout];
        self.annotationButtonItem.annotationToolbar.editableAnnotationTypes = editableTypes;
        
        
        // UI: Parse outline early, prevents possible toolbar update during the fade-in. (outline is lazily evaluated)
        //if (!PSPDFIsCrappyDevice()) [self.document.outlineParser outline];

        // Restore viewState.
        if ([self.document isKindOfClass:PSCMagazine.class]) {
            [self setViewState:((PSCMagazine *)self.document).lastViewState];
        }

        self.leftBarButtonItems = @[_closeButtonItem];

        // Change color.
        self.tintColor = [UIColor grayColor];
        
        //self.statusBarStyleSetting = PSPDFStatusBarDefault;
     // Change statusbar setting to your preferred style.
        //self.statusBarStyleSetting = PSPDFStatusBarDisable;
        //self.statusBarStyleSetting = self.statusBarStyleSetting | PSPDFStatusBarIgnore;
        
       // [self.navigationController setToolbarHidden:YES animated:YES];
        
    

    }
    

    return self;
}



-(void)shareBtn:(NSNotification *)notif

{
    
    
    
    NSString *str=(NSString *)[notif object];
    
    
    if ([str isEqualToString:@"share"])
    {
        [self setIsShare:YES];
        NSDictionary *dirtyAnnotations = [self.document.annotationParser dirtyAnnotations];
        if ([dirtyAnnotations count] == 0) {
            [self openMailComposer];
            
        }
        
        
        
        //
        //<<<<<<< HEAD
        //       [self setIsShare:YES];
        //        NSDictionary *dirtyAnnotations = [self.document.annotationParser dirtyAnnotations];
        //        if (![dirtyAnnotations count] == 0) {
        //            [self showSaveAsDialog];
        //=======
        //        if ([MFMailComposeViewController canSendMail]) {
        //            MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
        //            mailController.mailComposeDelegate = self;
        //            //NSString * pdfname=@"";
        //
        //                NSString *fileName = [self.magazine fileName];
        //
        //                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        //                NSString *documentsDirectory = [paths objectAtIndex:0];
        //            NSString *FolderPath;
        //            if ([UIAPPDelegate isMyTopic])
        //            {
        //                 FolderPath = [documentsDirectory stringByAppendingPathComponent:@"MyTopics"];
        //            }
        //            else
        //            {
        //                FolderPath = [documentsDirectory stringByAppendingPathComponent:@"Samples"];
        //
        //            }
        //                NSString* FilePath = [FolderPath stringByAppendingPathComponent:fileName];
        //
        //
        //                NSData *pdfData = [NSData dataWithContentsOfFile:FilePath];
        //                [mailController addAttachmentData:pdfData mimeType:@"application/pdf"fileName:fileName];
        //
        //            //pdfname = [NSString stringWithFormat:@"%@.",pdfname];
        //            //pdfname = [pdfname stringByReplacingOccurrencesOfString:@", ." withString:@""];
        //            [mailController setSubject:fileName];
        //            NSString *mailBody =   [[NSUserDefaults  standardUserDefaults]objectForKey:@"emailBody"];
        //
        //            NSString *mailSignature = [[NSUserDefaults  standardUserDefaults]objectForKey:@"emailSignature"];
        //            if([mailBody isEqualToString:@""]||mailBody==nil||[mailBody isEqualToString:@"(null)"])
        //            {
        //                mailBody=@"This mail is sent by ASSH Application";
        //            }
        //            if([mailSignature isEqualToString:@""]||mailSignature==nil||[mailSignature isEqualToString:@"(null)"])
        //
        //            {
        //                mailSignature=@"";
        //            }
        //            NSString *finalEmailbody=[NSString stringWithFormat:@"%@ \n\n\n %@ ",mailBody,mailSignature];
        //
        //            [mailController setMessageBody:finalEmailbody isHTML:NO];
        //
        //
        //            [self presentViewController:mailController animated:YES completion:nil];
        //            [self.popoverController dismissPopoverAnimated:YES];
        //            self.popoverController.delegate=nil;
        //>>>>>>> 25f4e0e1b5242577debddfda853e69fe98d48295
        //
        
        else
        {
            [self showSaveAsDialog];
        }
        
    }
    
    
    else if ([str isEqualToString:@"saveNewTopic"])
    {
        [self setIsShare:NO];
        
        [self showSaveAsDialog];
        
    }
    else if ([str isEqualToString:@"removeTopic"])
    {
        NSString *str = [self.magazine fileName];
        
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *documentDBFolderPath = [documentsDirectory stringByAppendingPathComponent:@"MyTopics"];
        documentDBFolderPath=[documentDBFolderPath stringByAppendingPathComponent:str];
        
        [fileManager removeItemAtPath:documentDBFolderPath error:&error];
        
        BOOL animated = YES;
        NSUInteger controllerCount = [self.navigationController.viewControllers count];
        if (controllerCount > 1 && [self.navigationController.viewControllers[controllerCount-2] isKindOfClass:[PSCGridController class]]) {
            animated = NO;
        }
        [self.navigationController popViewControllerAnimated:animated];
        [self.popoverController dismissPopoverAnimated:YES];
        self.popoverController.delegate=nil;
        
        
    }
    
    
    
    
}

-(void)openMailComposer
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
        mailController.mailComposeDelegate = self;
      //  NSString * pdfname=@"";
        NSString *fileName;
        if (self.isSaveasDialogonShare==YES)
        {
            //NSString *fileName = [self.magazine fileName];
            fileName=[textfield.text stringByAppendingString:@".pdf"];
            //self.isSaveasDialogonShare=NO;
        }
        else
        {
            
            fileName = [self.magazine fileName];
        }
        fileName = [UIAPPDelegate removeZZZ:fileName];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *FolderPath;
        if ([UIAPPDelegate isMyTopic])
        {
            FolderPath = [documentsDirectory stringByAppendingPathComponent:@"MyTopics"];
        }
        else
        {
            if (!self.isSaveasDialogonShare==YES)
            {
                if (self.isShared==YES) {
                    FolderPath = [documentsDirectory stringByAppendingPathComponent:@"MyTopics"];
                }
                else
                    FolderPath = [documentsDirectory stringByAppendingPathComponent:@"Samples"];
            }
            else
            {
                
                FolderPath = [documentsDirectory stringByAppendingPathComponent:@"MyTopics"];
                self.isSaveasDialogonShare=NO;
            }
            
        }
        
        NSString* FilePath = [FolderPath stringByAppendingPathComponent:fileName];
        
        
        
        NSData *pdfData = [NSData dataWithContentsOfFile:FilePath];
        [mailController addAttachmentData:pdfData mimeType:@"application/pdf"fileName:fileName];
        
        //pdfname = [NSString stringWithFormat:@"%@.",pdfname];
        //pdfname = [pdfname stringByReplacingOccurrencesOfString:@", ." withString:@""];
        [mailController setSubject:fileName];
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
        [self.popoverController dismissPopoverAnimated:YES];
        self.popoverController.delegate=nil;
        
        
    }
    else{
        UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"Share" message:@"No mail client configured on this device. Kindly configure any mail id before using the share option" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        
        [alert show];
        
    }
    
    
    
    
}


//-(void)openMailComposer
//{
//    if ([MFMailComposeViewController canSendMail]) {
//        MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
//        mailController.mailComposeDelegate = self;
//        NSString * pdfname=@"";
//        NSString *fileName;
//        if (self.isSaveasDialogonShare==YES)
//        {
//            //NSString *fileName = [self.magazine fileName];
//            fileName=[textfield.text stringByAppendingString:@".pdf"];
//            //self.isSaveasDialogonShare=NO;
//        }
//        else
//        {
//            
//            fileName = [self.magazine fileName];
//        }
//        
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        NSString *documentsDirectory = [paths objectAtIndex:0];
//        NSString *FolderPath;
//        if ([UIAPPDelegate isMyTopic])
//        {
//            FolderPath = [documentsDirectory stringByAppendingPathComponent:@"MyTopics"];
//        }
//        else
//        {
//            if (!self.isSaveasDialogonShare==YES)
//            {
//                FolderPath = [documentsDirectory stringByAppendingPathComponent:@"Samples"];
//            }
//            else
//            {
//                
//                FolderPath = [documentsDirectory stringByAppendingPathComponent:@"MyTopics"];
//                self.isSaveasDialogonShare=NO;
//            }
//            
//        }
//        NSString* FilePath = [FolderPath stringByAppendingPathComponent:fileName];
//        
//        
//        NSData *pdfData = [NSData dataWithContentsOfFile:FilePath];
//        [mailController addAttachmentData:pdfData mimeType:@"application/pdf"fileName:fileName];
//        
//        //pdfname = [NSString stringWithFormat:@"%@.",pdfname];
//        //pdfname = [pdfname stringByReplacingOccurrencesOfString:@", ." withString:@""];
//        [mailController setSubject:fileName];
//        NSString *mailBody =   [[NSUserDefaults  standardUserDefaults]objectForKey:@"emailBody"];
//        
//        NSString *mailSignature = [[NSUserDefaults  standardUserDefaults]objectForKey:@"emailSignature"];
//        if([mailBody isEqualToString:@""]||mailBody==nil||[mailBody isEqualToString:@"(null)"])
//        {
//            mailBody=@"This mail is sent by ASSH Application";
//        }
//        if([mailSignature isEqualToString:@""]||mailSignature==nil||[mailSignature isEqualToString:@"(null)"])
//            
//        {
//            mailSignature=@"";
//        }
//        NSString *finalEmailbody=[NSString stringWithFormat:@"%@ \n\n\n %@ ",mailBody,mailSignature];
//        
//        [mailController setMessageBody:finalEmailbody isHTML:NO];
//        
//        
//        [self presentViewController:mailController animated:YES completion:nil];
//        [self.popoverController dismissPopoverAnimated:YES];
//        self.popoverController.delegate=nil;
//        
//    }
//    else{
//        UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"Share" message:@"No mail client configured on this device. Kindly configure any mail id before using the share option" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
//        
//        [alert show];
//        
//    }
//}

-(void)home
{
    
    NSDictionary *dirtyAnnotations = [self.document.annotationParser dirtyAnnotations];
    if ([dirtyAnnotations count] == 0) {
        [self close];

    } else {
        [self showSaveAsDialog];
    }

    
}

- (void) showSaveAsDialog {
    NSString *str = [NSString stringWithFormat:@"%@", [[self.document.fileURL lastPathComponent] stringByReplacingOccurrencesOfString:@".pdf" withString:@""]];
    str = [UIAPPDelegate removeZZZ:str];
    UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"Save as new topic" message:@"\n \n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok",nil];
    // create text field
    textfield=[[UITextField alloc] initWithFrame:CGRectMake(20, 50, 240, 33)];
    [alert addSubview:textfield];
    textfield.text=str;
    textfield.backgroundColor=[UIColor whiteColor];
    [alert show];
    [self.popoverController dismissPopoverAnimated:YES];
    self.popoverController.delegate=nil;
    NSLog(@"self.magazine%@",self.magazine);
}

//-(void)deleteAnnotation:(CachedAnnotation *)cachedAnnotation{
 //  [self.pageCache[@(cachedAnnotation.annotation.page)] removeObject:cachedAnnotation];
//}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (PSCMagazine *)magazine {
    return (PSCMagazine *)self.document;
}

- (void)close {
    // If parent is PSCGridController, we have a custom animation in place.
    BOOL animated = YES;
    NSUInteger controllerCount = [self.navigationController.viewControllers count];
    if (controllerCount > 1 && [self.navigationController.viewControllers[controllerCount-2] isKindOfClass:[PSCGridController class]]) {
        animated = NO;
    }
    
       [self.navigationController popViewControllerAnimated:animated];
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewController


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // Save current viewState.
    if ([self.document isKindOfClass:PSCMagazine.class]) {
        ((PSCMagazine *)self.document).lastViewState = self.viewState;
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PSPDFViewController

#ifdef PSPDFCatalog
- (void)updateSettingsForRotation:(UIInterfaceOrientation)toInterfaceOrientation force:(BOOL)force {
    // Dynamically adapt toolbar (in landscape mode, we have a lot more space!)
    NSArray *leftToolbarItems = PSIsIpad() && UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? @[_closeButtonItem, _settingsButtomItem, _metadataButtonItem, _annotationListButtonItem] : @[_closeButtonItem, _settingsButtomItem];

    // Simple performance optimization.
    if ([leftToolbarItems count] != [self.leftBarButtonItems count] || force) {
        self.leftBarButtonItems = leftToolbarItems;
    }
}

- (void)updateSettingsForRotation:(UIInterfaceOrientation)toInterfaceOrientation {
    [super updateSettingsForRotation:toInterfaceOrientation];
    [self updateSettingsForRotation:toInterfaceOrientation force:NO];
}

#endif

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

// This is to present the most common features of PSPDFKit.
// iOS is all about choosing the right options for the user. You really shouldn't ship that.

- (void)globalVarChanged {
    // Preserve viewState, but only page, not contentOffset. (since we can change fitToWidth etc here)
    PSPDFViewState *viewState = [self viewState];
    viewState.zoomScale = 1;
    viewState.contentOffset = CGPointMake(0, 0);
    
    NSMutableDictionary *renderOptions = [self.document.renderOptions mutableCopy] ?: [NSMutableDictionary dictionary];
    NSDictionary *settings = [PSCSettingsController settings];
    [settings enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        // renderOptions need special treatment.
        if ([key isEqual:@"renderBackgroundColor"])     renderOptions[kPSPDFBackgroundFillColor] = obj;
        else if ([key isEqual:@"renderContentOpacity"]) renderOptions[kPSPDFContentOpacity] = obj;
        else if ([key isEqual:@"renderInvertEnabled"])  renderOptions[kPSPDFInvertRendering] = obj;
        
        else if (![key hasSuffix:@"ButtonItem"] && ![key hasPrefix:@"showTextBlocks"]){
            
            [self setValue:obj forKey:[PSCSettingsController setterKeyForGetter:key]];
        }
    }];
    self.document.renderOptions = renderOptions;
    
    UIButton *homeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *homeBtnImage = [UIImage imageNamed:@"home.png"];
    
    [homeBtn setBackgroundImage:homeBtnImage forState:UIControlStateNormal];
    [homeBtn addTarget:self action:@selector(home) forControlEvents:UIControlEventTouchUpInside];
    homeBtn.frame = CGRectMake(0, 0, 30, 30);
    
    //[tools addSubview:contentBtn];
    _closeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:homeBtn];
    
    // Defaults to nil, this would show the back arrow (but we want a custom animation, thus our own button)
    // NSString *closeTitle = PSIsIpad() ? NSLocalizedString(@"Main Screen", @"") : NSLocalizedString(@"Back", @"");
    // _closeButtonItem = [[UIBarButtonItem alloc] initWithTitle:closeTitle style:UIBarButtonItemStyleBordered target:self action:@selector(close:)];
    _settingsButtomItem = [[PSCSettingsBarButtonItem alloc] initWithPDFViewController:self];
    
#ifdef PSPDFCatalog
    _metadataButtonItem = [[PSCMetadataBarButtonItem alloc] initWithPDFViewController:self];
    _annotationListButtonItem = [[PSCAnnotationTableBarButtonItem alloc] initWithPDFViewController:self];
    [self updateSettingsForRotation:self.interfaceOrientation force:YES];
#endif
    
    self.barButtonItemsAlwaysEnabled = @[_closeButtonItem];
    
    self.navigationItem.leftBarButtonItem=_closeButtonItem;

    
    NSMutableArray *rightBarButtonItems = [NSMutableArray array];
//    UIButton *shareBtn = [[UIButton buttonWithType:UIButtonTypeRoundedRect];
    UIImage *shareBtnImage = [UIImage imageNamed:@"action12.png"];
//    [shareBtn setBackgroundImage:shareBtnImage forState:UIControlStateNormal];
//    [shareBtn addTarget:self action:@selector(shareAction) forControlEvents:UIControlEventTouchUpInside];
//    shareBtn.frame = CGRectMake(0, 0, 25, 25);
//    self.shareBarbuttonItem=[[UIBarButtonItem alloc] initWithCustomView:shareBtn];
    
                          
    self.shareBarbuttonItem = [[UIBarButtonItem alloc] initWithImage:shareBtnImage style:UIBarButtonItemStylePlain target:self action:@selector(shareAction)];
 
    
    if (PSIsIpad()) {
        if ([settings[NSStringFromSelector(@selector(bookmarkButtonItem))] boolValue]) {
            [rightBarButtonItems addObject:self.bookmarkButtonItem];
        }
        if ([settings[NSStringFromSelector(@selector(outlineButtonItem))] boolValue]) {
            [rightBarButtonItems addObject:self.outlineButtonItem];
        
        }
        
    }
    if ([settings[NSStringFromSelector(@selector(annotationButtonItem))] boolValue]) {
        [rightBarButtonItems addObject:self.annotationButtonItem];
    }
    
   [rightBarButtonItems addObject:self.shareBarbuttonItem];

    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    // reload scroll view and restore viewState
    [self reloadData];
    [self setViewState:viewState animated:NO];
}


///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PSPDFViewControllerDelegate

// Allow control if a page should be scrolled to.
- (BOOL)pdfViewController:(PSPDFViewController *)pdfController shouldScrollToPage:(NSUInteger)page {
    return YES;
}

// Time to adjust PSPDFViewController before a PSPDFDocument is displayed.
- (void)pdfViewController:(PSPDFViewController *)pdfController willDisplayDocument:(PSPDFDocument *)document {
    pdfController.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen_texture_dark"]];
    // show pdf title and fileURL
    if (document) {
        /*
        NSString *fileName = PSPDFStripPDFFileType([document.fileURL lastPathComponent]);
        if (fileName == nil) {
            self.title = document.title;
        } else
        if (PSIsIpad() && ![document.title isEqualToString:fileName]) {
            //self.title = [NSString stringWithFormat:@"%@ (%@)", document.title, [document.fileURL lastPathComponent]];
            self.title = [NSString stringWithFormat:@"%@", [[document.fileURL lastPathComponent] stringByReplacingOccurrencesOfString:@".pdf" withString:@""]];
        }
        // Remove the unwanted "zzz" from the title which was appended earlier for showing some pdfs at end
        if ([self.title rangeOfString:@"zzz"].location != NSNotFound) {
            NSMutableString *title = [self.title mutableCopy];
            [title replaceOccurrencesOfString:@"zzz" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, title.length)];
            self.title = title;
        }
        */
        self.title = [NSString stringWithFormat:@"%@", [[document.fileURL lastPathComponent] stringByReplacingOccurrencesOfString:@".pdf" withString:@""]];
        self.title = [UIAPPDelegate removeZZZ:self.title];
    }
}



-(BOOL)pdfViewController:(PSPDFViewController *)pdfController didTapOnAnnotation:(PSPDFAnnotation *)annotation annotationPoint:(CGPoint)annotationPoint annotationView:(UIView<PSPDFAnnotationViewProtocol> *)annotationView pageView:(PSPDFPageView *)pageView viewPoint:(CGPoint)viewPoint {
    
    PSCLog(@"didTapOnAnnotation:%@ annotationPoint:%@ annotationView:%@ pageView:%@ viewPoint:%@", annotation, NSStringFromCGPoint(annotationPoint), annotationView, pageView, NSStringFromCGPoint(viewPoint));
    BOOL handled = NO;
    return handled;
}

- (BOOL)pdfViewController:(PSPDFViewController *)pdfController didTapOnPageView:(PSPDFPageView *)pageView atPoint:(CGPoint)viewPoint {
    CGPoint screenPoint = [self.view convertPoint:viewPoint fromView:pageView];
    CGPoint pdfPoint = [pageView convertViewPointToPDFPoint:viewPoint];
    PSCLog(@"Page %d tapped at %@ screenPoint:%@ PDFPoint%@ zoomScale:%.1f.", pageView.page, NSStringFromCGPoint(viewPoint), NSStringFromCGPoint(screenPoint), NSStringFromCGPoint(pdfPoint), pageView.scrollView.zoomScale);

    return NO; // touch not used.
}

static NSString *PSCGestureStateToString(UIGestureRecognizerState state) {
    switch (state) {
        case UIGestureRecognizerStateBegan:     return @"Began";
        case UIGestureRecognizerStateChanged:   return @"Changed";
        case UIGestureRecognizerStateEnded:     return @"Ended";
        case UIGestureRecognizerStateCancelled: return @"Cancelled";
        case UIGestureRecognizerStateFailed:    return @"Failed";
        case UIGestureRecognizerStatePossible:  return @"Possible";
        default: return @"";
    }
}

- (BOOL)pdfViewController:(PSPDFViewController *)pdfController didLongPressOnPageView:(PSPDFPageView *)pageView atPoint:(CGPoint)viewPoint gestureRecognizer:(UILongPressGestureRecognizer *)gestureRecognizer {
    // Only show log on start, prevents excessive log statements.
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint screenPoint = [self.view convertPoint:viewPoint fromView:pageView];
        CGPoint pdfPoint = [pageView convertViewPointToPDFPoint:viewPoint];
        PSCLog(@"Page %d long pressed at %@ screenPoint:%@ PDFPoint%@ zoomScale:%.1f. (state: %@)", pageView.page, NSStringFromCGPoint(viewPoint), NSStringFromCGPoint(screenPoint), NSStringFromCGPoint(pdfPoint), pageView.scrollView.zoomScale, PSCGestureStateToString(gestureRecognizer.state));
    }
    return NO; // Touch not used.
}

- (void)pdfViewController:(PSPDFViewController *)pdfController didShowPageView:(PSPDFPageView *)pageView {
    //PSCLog(@"page %d displayed. (document: %@)", pageView.page, pageView.document.title);

    if ([[PSCSettingsController settings][@"showTextBlocks"] boolValue]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            for (PSPDFPageView *visiblePageView in self.visiblePageViews) {
                [self.document textParserForPage:visiblePageView.page];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                for (PSPDFPageView *visiblePageView in self.visiblePageViews) {
                    [visiblePageView.selectionView showTextFlowData:YES animated:NO];
                }
            });
        });
    }else {
        for (PSPDFPageView *visiblePageView in self.visiblePageViews) {
            [visiblePageView.selectionView showTextFlowData:NO animated:NO];
        }
    }
}

- (void)pdfViewController:(PSPDFViewController *)pdfController didRenderPageView:(PSPDFPageView *)pageView {
    PSCLog(@"Page %d rendered. (document: %@)", pageView.page, pageView.document.title);
}

- (void)pdfViewController:(PSPDFViewController *)pdfController didLoadPageView:(PSPDFPageView *)pageView {
    if ([[PSCSettingsController settings][@"showTextBlocks"] boolValue]) {
        for (PSPDFPageView *visiblePageView in self.visiblePageViews) {
            [visiblePageView.selectionView showTextFlowData:NO animated:NO];
        }
    }
}


- (BOOL)pdfViewController:(PSPDFViewController *)pdfController shouldShowController:(id)viewController embeddedInController:(id)controller animated:(BOOL)animated {
    PSCLog(@"shouldShowViewController: %@ embeddedIn:%@ animated: %d.", viewController, controller, animated);
    return YES;
}

- (void)pdfViewController:(PSPDFViewController *)pdfController didShowController:(id)viewController embeddedInController:(id)controller animated:(BOOL)animated {
    PSCLog(@"didShowViewController: %@ embeddedIn:%@ animated: %d.", viewController, controller, animated);
}

- (void)pdfViewController:(PSPDFViewController *)pdfController didEndPageDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGPoint targetOffsetPoint = targetContentOffset ? *targetContentOffset : CGPointZero;
    PSCLog(@"didEndPageDraggingwillDecelerate:%@ velocity:%@ targetContentOffset:%@.", decelerate ? @"YES" : @"NO", NSStringFromCGPoint(velocity), NSStringFromCGPoint(targetOffsetPoint));
}

- (void)pdfViewController:(PSPDFViewController *)pdfController didEndPageZooming:(UIScrollView *)scrollView atScale:(CGFloat)scale {
    PSCLog(@"didEndPageDraggingAtScale: %f", scale);
}

- (BOOL)pdfViewController:(PSPDFViewController *)pdfController shouldSelectText:(NSString *)text withGlyphs:(NSArray *)glyphs atRect:(CGRect)rect onPageView:(PSPDFPageView *)pageView {
    // Example how to limit text selection.
    // return [text length] > 10;
    return YES;
}

-(NSArray *)pdfViewController:(PSPDFViewController *)pdfController shouldShowMenuItems:(NSArray *)menuItems atSuggestedTargetRect:(CGRect)rect forSelectedText:(NSString *)selectedText inRect:(CGRect)textRect onPageView:(PSPDFPageView *)pageView {
    
    
    // This is an example how to customize the text selection menu.
    // It helps for debugging text extraction issues. Don't ship this feature.
    NSMutableArray *newMenuItems = [menuItems mutableCopy];
    


    
    if (PSIsIpad()) { // looks bad on iPhone, no space
        PSPDFMenuItem *menuItem = [[PSPDFMenuItem alloc] initWithTitle:@"Show Text" block:^{
            [[[UIAlertView alloc] initWithTitle:@"Custom Show Text Feature" message:selectedText delegate:nil cancelButtonTitle:PSPDFLocalize(@"Ok") otherButtonTitles:nil] show];
        } identifier:@"Show Text"];
        [newMenuItems addObject:menuItem];
    }
    return newMenuItems;
}

// Annotations

/// Called before an annotation will be selected. (but after didTapOnAnnotation)
- (BOOL)pdfViewController:(PSPDFViewController *)pdfController shouldSelectAnnotation:(PSPDFAnnotation *)annotation onPageView:(PSPDFPageView *)pageView {
    PSCLog(@"should select %@?", annotation);
    return YES;
}

/// Called after an annotation has been selected.
- (void)pdfViewController:(PSPDFViewController *)pdfController didSelectAnnotation:(PSPDFAnnotation *)annotation onPageView:(PSPDFPageView *)pageView {
    PSCLog(@"did select %@.", annotation);
}

/// Called before we're showing the menu for an annotation.
- (NSArray *)pdfViewController:(PSPDFViewController *)pdfController shouldShowMenuItems:(NSArray *)menuItems atSuggestedTargetRect:(CGRect)rect forAnnotation:(PSPDFAnnotation *)annotation inRect:(CGRect)textRect onPageView:(PSPDFPageView *)pageView {
    
    PSCLog(@"showing menu %@ for %@", menuItems, annotation);
    

    NSMutableArray *newMenuItems = [menuItems mutableCopy];
    for (PSPDFMenuItem *menuItem in menuItems) {
        if ([menuItem isKindOfClass:[PSPDFMenuItem class]] && [menuItem.identifier isEqualToString:@"Signature"]) {
            [newMenuItems removeObjectIdenticalTo:menuItem];
        
        }
        if ([menuItem isKindOfClass:[PSPDFMenuItem class]] && [menuItem.identifier isEqualToString:@"Rectangle"]) {
            [newMenuItems removeObjectIdenticalTo:menuItem];
            ;
        }
        if ([menuItem isKindOfClass:[PSPDFMenuItem class]] && [menuItem.identifier isEqualToString:@"Stamp"]) {
            [newMenuItems removeObjectIdenticalTo:menuItem];
        }
        if ([menuItem isKindOfClass:[PSPDFMenuItem class]] && [menuItem.identifier isEqualToString:@"Line"]) {
            [newMenuItems removeObjectIdenticalTo:menuItem];
        }
        if ([menuItem isKindOfClass:[PSPDFMenuItem class]] && [menuItem.identifier isEqualToString:@"Free Text"]) {
            [newMenuItems removeObjectIdenticalTo:menuItem];
        }
       
        if ([menuItem isKindOfClass:[PSPDFMenuItem class]] && [menuItem.identifier isEqualToString:@"Ellipse"]) {
            [newMenuItems removeObjectIdenticalTo:menuItem];
        }
        
        if ([menuItem isKindOfClass:[PSPDFMenuItem class]] && [menuItem.identifier isEqualToString:@"Highlight"]) {
            [newMenuItems removeObjectIdenticalTo:menuItem];
        }
       
        


    }
    // Print highlight contents
    if ([annotation isKindOfClass:PSPDFHighlightAnnotation.class]){
        NSString *highlightedString = [(PSPDFHighlightAnnotation *)annotation highlightedString];
        PSCLog(@"Highlighted value: %@", highlightedString);
    }

    // Example how to rename menu items.
    //for (PSPDFMenuItem *menuItem in menuItems) {
    //    menuItem.title = @"Test";
    //}

    return newMenuItems;
}


///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - PSPDFDocumentDelegate

- (void)saveAnnotations {
    NSLog(@"Annotations before saving: %@", [self.document.annotationParser annotationsForPage:0 type:PSPDFAnnotationTypeAll]);
    
    NSDictionary *dirtyAnnotations = [self.document.annotationParser dirtyAnnotations];
    NSLog(@"Dirty Annotations: %@", dirtyAnnotations);
    
    if (self.document.data) NSLog(@"Length of NSData before saving: %d", self.document.data.length);
    
    NSError *error = nil;
    if (![self.document saveChangedAnnotationsWithError:&error]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to save annotations.", @"") message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", @"") otherButtonTitles:nil] show];
    }else {
        [self reloadData];
        NSLog(@"---------------------------------------------------");
        NSLog(@"Annotations after saving: %@", [self.document.annotationParser annotationsForPage:0 type:PSPDFAnnotationTypeAll]);
        //[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", @"") message:[NSString stringWithFormat:NSLocalizedString(@"Saved %d annotation(s)", @""), dirtyAnnotationCount] delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", @"") otherButtonTitles:nil] show];
        
        if (self.document.data) NSLog(@"Length of NSData after saving: %d", self.document.data.length);
    }
}

- (void)pdfDocument:(PSPDFDocument *)document didSaveAnnotations:(NSArray *)annotations {
//        NSLog(@"Successfully saved annotations: %@", annotations);
//        NSLog(@" count==%i",[annotations count]);
//        
        
           
     if (document.data) NSLog(@"This is your time to save the updated data!");
    
}



// Image has priority, so nil that out.
- (UIImage *)image {
    return nil;
}


- (void)pdfDocument:(PSPDFDocument *)document failedToSaveAnnotations:(NSArray *)annotations withError:(NSError *)error {
    NSLog(@"Failed to save annotations: %@", [error localizedDescription]);
}


- (BOOL)addBookmarkForPage:(NSUInteger)page
{
    return YES;
    
}
- (BOOL)removeBookmarkForPage:(NSUInteger)page
{
    return YES;
}


-(void)shareAction
{
   // [self saveAnnotations];

    if(![self.popoverController isPopoverVisible]){
        
        self.sharePopover = [[SharePopoverView alloc] initWithNibName:@"SharePopoverView" bundle:nil];
       // self.sharePopover.tempTopicsArray=_filteredData;
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.sharePopover];
        
        //[popoverController setDelegate:self];
        [self.popoverController setPopoverContentSize:CGSizeMake(255.0f, 200.0f)];
        if (self.view.window != nil)
        {
            
            if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {

            [self.popoverController presentPopoverFromRect:CGRectMake(535, -110, 111, 111) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
            }
            else
            {
              [self.popoverController presentPopoverFromRect:CGRectMake(790, -110, 111, 111) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
            }
        }
        
    }else {
        [self.popoverController dismissPopoverAnimated:YES];
        self.popoverController.delegate=nil;
    }
  
    
}

- (void) alertView:(UIAlertView *) alertSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if (buttonIndex==0 ) {
        
        [self.document clearCache];
        if (![self isShare]==YES) {
            [self close];
            
        }
        
    }
    else
    {
        // show activity indicator
        [MBProgressHUD showHUDAddedTo:self.view animated:NO];
        
        
       // NSString *str = [self.magazine fileName];
        // NSString *str = [NSString stringWithFormat:@"%@", [self.document.fileURL lastPathComponent]];
        
        //self.documentFileName = [NSString stringWithFormat:@"%@", self.document.title];
        
        NSString *filename=[textfield.text stringByAppendingString:@".pdf"];
        
        //get the doc directory path
      //  NSFileManager *fileManager = [NSFileManager defaultManager];
       // NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
    //    NSString *documentDBFolderPath = [documentsDirectory stringByAppendingPathComponent:@"Samples"];
        //current file path
       /// NSString *currntPath=[documentDBFolderPath stringByAppendingPathComponent:str];
        
       // NSString *documentDBFolderPathinMyTopic = [documentsDirectory stringByAppendingPathComponent:@"MyTopics"];
        
        if ([UIAPPDelegate isMyTopic])
        {
            NSString *newPath;
            newPath=[documentsDirectory stringByAppendingPathComponent:@"MyTopics"];
            newPath = [newPath stringByAppendingPathComponent:filename];
            NSURL *newURL = [NSURL fileURLWithPath:newPath];
            
            NSError *error;
            if (![[NSFileManager defaultManager] copyItemAtURL:self.document.fileURL toURL:newURL error:&error]) {
                PSPDFLogWarning(@"Failed to copy file to %@: %@", newURL.path, [error localizedDescription]);
            }else {
                
                // Since the annotation has already been edited, we copy the file *before* it will be saved
                // then save the current state and switch out the documents.
                
                
                if (![self.document saveChangedAnnotationsWithError:&error]) {
                    PSPDFLogWarning(@"Failed to save annotations: %@", [error localizedDescription]);
                }
                NSURL *tmpURL = [newURL URLByAppendingPathExtension:@"temp"];
                if (![[NSFileManager defaultManager] moveItemAtURL:self.document.fileURL toURL:tmpURL error:&error]) {
                    PSPDFLogWarning(@"Failed to move file: %@", [error localizedDescription]); return;
                }
                if (![[NSFileManager defaultManager] moveItemAtURL:newURL toURL:self.document.fileURL error:&error]) {
                    PSPDFLogWarning(@"Failed to move file: %@", [error localizedDescription]); return;
                }
                if (![[NSFileManager defaultManager] moveItemAtURL:tmpURL toURL:newURL error:&error]) {
                    PSPDFLogWarning(@"Failed to move file: %@", [error localizedDescription]); return;
                }
                // Finally update the fileURL, this will clear the current document cache.
                self.document.fileURL = newURL;
                self.title = [NSString stringWithFormat:@"%@", [[self.document.fileURL lastPathComponent] stringByReplacingOccurrencesOfString:@".pdf" withString:@""]];
            }
            if (![self isShare]==YES) {
                [self close];
            }
            else
            {
                
                self.isSaveasDialogonShare=YES;
                [self openMailComposer];
            }
            
            
            
        }
        else
            
        {
            
            
            
            NSString *newPath1;
            newPath1=[documentsDirectory stringByAppendingPathComponent:@"MyTopics"];
            newPath1 = [newPath1 stringByAppendingPathComponent:filename];
            NSURL *newURL1 = [NSURL fileURLWithPath:newPath1];
            
            NSError *error;
            if (![[NSFileManager defaultManager] copyItemAtURL:self.document.fileURL toURL:newURL1 error:&error]) {
                PSPDFLogWarning(@"Failed to copy file to %@: %@", newURL1.path, [error localizedDescription]);
            }else {
                
                // Since the annotation has already been edited, we copy the file *before* it will be saved
                // then save the current state and switch out the documents.
                
                
                if (![self.document saveChangedAnnotationsWithError:&error]) {
                    PSPDFLogWarning(@"Failed to save annotations: %@", [error localizedDescription]);
                }
                NSURL *tmpURL = [newURL1 URLByAppendingPathExtension:@"temp"];
                if (![[NSFileManager defaultManager] moveItemAtURL:self.document.fileURL toURL:tmpURL error:&error]) {
                    PSPDFLogWarning(@"Failed to move file: %@", [error localizedDescription]); return;
                }
                if (![[NSFileManager defaultManager] moveItemAtURL:newURL1 toURL:self.document.fileURL error:&error]) {
                    PSPDFLogWarning(@"Failed to move file: %@", [error localizedDescription]); return;
                }
                if (![[NSFileManager defaultManager] moveItemAtURL:tmpURL toURL:newURL1 error:&error]) {
                    PSPDFLogWarning(@"Failed to move file: %@", [error localizedDescription]); return;
                }
                // Finally update the fileURL, this will clear the current document cache.
                self.document.fileURL = newURL1;
                self.title = [NSString stringWithFormat:@"%@", [[self.document.fileURL lastPathComponent] stringByReplacingOccurrencesOfString:@".pdf" withString:@""]];
                
                if (![self isShare]==YES) {
                    [self close];
                }
                else
                {
                    
                    self.isSaveasDialogonShare=YES;
                    [self openMailComposer];
                }
            }
            
            
        }
        self.isShared=YES;
        // hide activity indicator
        [MBProgressHUD hideHUDForView:self.view animated:NO];
        
    }
}





@end
