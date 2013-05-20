//
//  ASSHAppDelegate.h
//  ASSH
//
//  Created by Sanjeev Jha on 01/04/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import <UIKit/UIKit.h>


#define UIAPPDelegate ((ASSHAppDelegate *)[[UIApplication sharedApplication] delegate])
@class PSCGridViewController;
@interface ASSHAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property(nonatomic,strong)UINavigationController *navigationController;
@property(nonatomic,assign) BOOL isSorting;
@property(nonatomic,assign) BOOL isMyTopic;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
-(void)insertData:(NSArray *)pdfArray;
-(NSMutableArray *)fetchData;

-(void)addBookmark:(NSString *)book;
-(void)removeBookmark:(NSString *)book;
-(NSArray *)fetchBookmarks;



@end
