//
//  ASSHViewController.m
//  ASSH
//
//  Created by Sanjeev Jha on 03/04/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import "ASSHViewController.h"
#import "PSCGridController.h"
//#import "PSCTabbedExampleViewController"

@interface ASSHViewController ()

@end

@implementation ASSHViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSError *error;
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    
//    NSString *txtPath = [documentsDirectory stringByAppendingPathComponent:@"txtFile.txt"];
//    
//    if ([fileManager fileExistsAtPath:txtPath] == YES) {
//        [fileManager removeItemAtPath:txtPath error:&error];
//    }
//    
//    
//    NSURL *samplesURL = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"Samples"];
//    
//    if
//    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"txtFile" ofType:@"txt"];
//    [fileManager copyItemAtPath:resourcePath toPath:txtPath error:&error];
    
    
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
    
    
    
    
    // Changes done by Chandan to accomodate new requirement of keeping my topics separate
   
    NSString *documentDBFolderPathForTopic = [documentsDirectory stringByAppendingPathComponent:@"MyTopics"];
    
    if (![fileManager fileExistsAtPath:documentDBFolderPathForTopic]) {
        //Create Directory!
        [fileManager createDirectoryAtPath:documentDBFolderPathForTopic withIntermediateDirectories:NO attributes:nil error:&error];
    } else {
        NSLog(@"Directory exists! %@", documentDBFolderPathForTopic);
    }
    
    self.navigationController.navigationBarHidden=YES;
    [super viewDidLoad];
     self.navigationController.navigationBar.tintColor=[UIColor colorWithRed:0.847 green:0.9255 blue:0.9725 alpha:1];
   
    
}




-(IBAction)StartAction:(id)sender
{
    //open the list of pdfs
    PSCGridController *gridController = [[PSCGridController alloc] init];
    [self.navigationController pushViewController:gridController animated:YES];

}
-(void)viewDidUnload
{
    self.navigationController.navigationBarHidden=NO;
}

- (void)didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


@end
