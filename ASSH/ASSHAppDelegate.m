//
//  ASSHAppDelegate.m
//  ASSH
//
//  Created by Sanjeev Jha on 01/04/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import "ASSHAppDelegate.h"
#import "PSCGridController.h"
#import "ASSHViewController.h"
#import "MyTopics.h"
#import "CustomNavigationController.h"

@implementation ASSHAppDelegate
@synthesize navigationController;
@synthesize window;@synthesize viewController;
@synthesize isSorting;
@synthesize isMyTopic;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
//    //self.window.backgroundColor = [UIColor whiteColor];
    
    // sanjeev
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentDBFolderPath = [documentsDirectory stringByAppendingPathComponent:@"Samples"];
    
    NSString *resourceDBFolderPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Samples"];
    
    if (![fileManager fileExistsAtPath:documentDBFolderPath]) {
        //Create Directory!
        [fileManager createDirectoryAtPath:documentDBFolderPath withIntermediateDirectories:NO attributes:nil error:&error];
        
    } else {
        
        NSLog(@"Directory exists! %@", documentDBFolderPath);
        
    }
    
    
    
    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:resourceDBFolderPath error:&error];
    for (NSString *s in fileList) {
        NSString *newFilePath = [documentDBFolderPath stringByAppendingPathComponent:s];
        NSString *oldFilePath = [resourceDBFolderPath stringByAppendingPathComponent:s];
        if (![fileManager fileExistsAtPath:newFilePath]) {
            //File does not exist, copy it
            [fileManager copyItemAtPath:oldFilePath toPath:newFilePath error:&error];
        } else {
            NSLog(@"File exists: %@", newFilePath);
        }
        
    }
    
    
    
    NSString *resourceDBFolderPathNew = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"SpecialPDF"];
    NSString *documentDBFolderPathNew = [documentsDirectory stringByAppendingPathComponent:@"MyTopics"];

    
    // Changes done by Chandan to accomodate new requirement of keeping my topics separate
    
    NSString *documentDBFolderPathForTopic = [documentsDirectory stringByAppendingPathComponent:@"MyTopics"];
    
    if (![fileManager fileExistsAtPath:documentDBFolderPathForTopic]) {
        //Create Directory!
        [fileManager createDirectoryAtPath:documentDBFolderPathForTopic withIntermediateDirectories:NO attributes:nil error:&error];
    } else {
        NSLog(@"Directory exists! %@", documentDBFolderPathForTopic);
    }
    
    
    NSArray *fileList1 = [fileManager contentsOfDirectoryAtPath:resourceDBFolderPathNew error:&error];
    for (NSString *s in fileList1) {
        NSString *newFilePath = [documentDBFolderPathNew stringByAppendingPathComponent:s];
        NSString *oldFilePath = [resourceDBFolderPathNew stringByAppendingPathComponent:s];
        if (![fileManager fileExistsAtPath:newFilePath]) {
            //File does not exist, copy it
            [fileManager copyItemAtPath:oldFilePath toPath:newFilePath error:&error];
        } else {
            NSLog(@"File exists: %@", newFilePath);
        }
        
    }
    
    PSCGridController *gridController = [[PSCGridController alloc] init];
    navigationController = [[CustomNavigationController alloc]
                            initWithRootViewController:gridController]; // iOS 6 autorotation fix
    [navigationController setNavigationBarHidden:YES animated:NO];
    
   self.navigationController.navigationBarHidden=YES;
    self.navigationController.navigationBar.tintColor=[UIColor colorWithRed:0.847 green:0.9255 blue:0.9725 alpha:1];
    
   

   // self.navigationController=[[UINavigationController alloc] initWithRootViewController:gridController];
    
    self.window.rootViewController = self.navigationController;
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ASSHModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ASSHModel.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
-(void)addBookmark:(NSString *)book
{
    NSError *error = nil;
    MyTopics *bookmark = [NSEntityDescription
                          insertNewObjectForEntityForName:@"Bookmarks" inManagedObjectContext:self.managedObjectContext];
    
    bookmark.bookName = book;
    
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Recording, couldn't save: %@", [error localizedDescription]);
    }
}
-(void)removeBookmark:(NSString *)book
{
    
    NSEntityDescription *productEntity=[NSEntityDescription entityForName:@"Bookmarks" inManagedObjectContext:[self managedObjectContext]];
    NSFetchRequest *fetch=[[NSFetchRequest alloc] init];
    [fetch setEntity:productEntity];
    NSPredicate *p=[NSPredicate predicateWithFormat:@"bookName == %@",book];
    [fetch setPredicate:p];
    //... add sorts if you want them
    NSError *Error;
    NSArray *fetchedProducts=[[self managedObjectContext] executeFetchRequest:fetch error:&Error];
    for (NSManagedObject *product in fetchedProducts) {
        
        [[self managedObjectContext] deleteObject:product];
        
    }
    
    if (![self.managedObjectContext save:&Error]) {
        NSLog(@"Recording, couldn't save: %@", [Error localizedDescription]);
    }

    
}
-(NSMutableArray *)fetchBookmarks
{
NSError *error = nil;
NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
NSEntityDescription *entity = [NSEntityDescription entityForName:@"Bookmarks"
                                          inManagedObjectContext:self. managedObjectContext];
[fetchRequest setEntity:entity];
NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
NSMutableArray *result=[[NSMutableArray alloc] init];
for (MyTopics *info in fetchedObjects)
{
    NSLog(@"%@",info.bookName);
    [result addObject:info.bookName];
}

return result;
}

-(void)insertData:(NSArray *)pdfArray;
{
    NSString *pdfName=[pdfArray objectAtIndex:0];
    NSString *content=[pdfArray objectAtIndex:1];
    NSString *index=[pdfArray objectAtIndex:2];
    NSInteger indexpage= [index integerValue];
    NSError *error = nil;
    MyTopics *empDetail = [NSEntityDescription
                           insertNewObjectForEntityForName:@"MyTopics" inManagedObjectContext:self.managedObjectContext];
    empDetail.bookName = pdfName;
    empDetail.content = content;
    empDetail.indexOnPage = indexpage;
    
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Recording, couldn't save: %@", [error localizedDescription]);
    }
}

-(NSMutableArray *)fetchData
{
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MyTopics"
                                              inManagedObjectContext:self. managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
     NSMutableArray *result=[[NSMutableArray alloc] init];
    for (MyTopics *info in fetchedObjects)
    {
        NSMutableDictionary *dict=[[NSMutableDictionary alloc] init];
        if (info.bookName) {
            [dict setObject:info.bookName forKey:@"pdfName"];
            }
        if (info.content) {
            [dict setObject:info.content forKey:@"content"];
        }
        if (info.indexOnPage) {
            NSString *str=[NSString stringWithFormat:@"%i",info.indexOnPage];
            [dict setObject:str forKey:@"index"];
        }
           [result addObject:dict];
    }
    
   return result;
    
}


@end
