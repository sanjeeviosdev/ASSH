//
//  PSCBookmarkParser.m
//  PSPDFCatalog
//
//  Copyright (c) 2012-2013 Peter Steinberger. All rights reserved.
//

#import "PSCBookmarkParser.h"
#import "ASSHAppDelegate.h"

@implementation PSCBookmarkParser

- (BOOL)addBookmarkForPage:(NSUInteger)page {
   // NSLog(@"Add Bookmark: %d", page);
  //  NSLog(@"%@",self.document);
    NSLog(@"%@",[self.document files][0]);
     NSString *pdfName=[self.document files][0];
    
    [UIAPPDelegate addBookmark:pdfName];


    return [super addBookmarkForPage:page];
}

- (BOOL)removeBookmarkForPage:(NSUInteger)page {
    
   // NSLog(@"%@",self.document);
   // NSLog(@"Remove Bookmark: %d", page);
     NSString *pdfName=[self.document files][0];
    [UIAPPDelegate removeBookmark:pdfName];
    return [super removeBookmarkForPage:page];
}

// block bookmark loading
- (NSArray *)loadBookmarks {
    return @[];
}

- (void)saveBookmarks {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIAlertView alloc] initWithTitle:@"Bookmark Subclass Message" message:[NSString stringWithFormat:@"Intercepted bookmark saving; current bookmarks are: %@", self.bookmarks] delegate:nil cancelButtonTitle:PSPDFLocalize(@"Ok") otherButtonTitles:nil] show];
    });
}

@end
