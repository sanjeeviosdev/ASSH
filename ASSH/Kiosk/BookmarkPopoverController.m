//
//  BookmarkPopoverController.m
//  ASSH
//
//  Created by Sanjeev Jha on 17/04/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import "BookmarkPopoverController.h"
#import "ASSHAppDelegate.h"
#import "PSCBookmarkParser.h"
#import "PSCCustomBookmarkBarButtonItem.h"

@interface BookmarkPopoverController ()

@end

@implementation BookmarkPopoverController

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
    [super viewDidLoad];
    
    
    
   // NSLog(@"%@",self.bookmarkArray) ;
    self.searchBar.delegate=self;
    self.topicsArray=[self.tempTopicsArray copy];
    self.bookmarkArray=[UIAPPDelegate fetchBookmarks];
    
    
//    NSString *searchString = _searchBar.text;
//    if ([searchString length]) { // title CONTAINS[cd] '%@' ||
//        NSString *predicate = [NSString stringWithFormat:@"fileURL.path CONTAINS[cd] '%@'", searchString];
//        self.topicsArray = [self.topicsArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicate]];
//    }
    
    NSLog(@"topics array %@",self.tempTopicsArray);
    

    [self.bookmarkTable reloadData];
    
//    UIBarButtonItem *editBarButton=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(EditTable:)];
//    self.toolbarItems=[NSArray]
    
    // Do any additional setup after loading the view from its nib.
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
    
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //#warning Incomplete method implementation.
    // Return the number of rows in the section.
    if ([self.bookmarkArray count]> 0) {
        self.topicsArray=nil;
        self.topicsArray=[[NSArray alloc] init];
        self.topicsArray=[self.tempTopicsArray copy];
        NSMutableArray *magsArray=[[NSMutableArray alloc]init];
       // NSArray *names = [self.bookmarkArray valueForKey:@"pdfName"];
        //return [self.markedTopics count];
        for (PSCMagazine * mag in self.topicsArray) {
            if([self.bookmarkArray containsObject:mag.fileName] == YES ) {
                [magsArray addObject:mag];
            }
        }
        self.topicsArray=[magsArray copy];
        
        NSString *searchString = _searchBar.text;
        if ([searchString length]) { // title CONTAINS[cd] '%@' ||
            
            NSString *predicate = [NSString stringWithFormat:@"fileURL.path CONTAINS[cd] '%@'", searchString];
            self.topicsArray = [self.topicsArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicate]];
        }
        
        NSLog(@"topicsArray==%@",self.topicsArray);
        
        UILabel *lbl=(UILabel *)[self.view viewWithTag:80000000];
        if (lbl) {
            [lbl removeFromSuperview];
        }
        
            
            if ([self.topicsArray count]==0) {
                
                UILabel *lbl=[[UILabel alloc] initWithFrame:CGRectMake(100, 50, 250, 33)];
                lbl.tag=80000000;
                lbl.text=@" No match Found";
                lbl.textColor=[UIColor blackColor];
                lbl.backgroundColor=[UIColor clearColor];
                [self.bookmarkTable addSubview:lbl];
                

            
            
           
        }
        
         return [self.topicsArray count];
        
    }
    else
    {
        
       
        
        
          
        
        
             
        
        return 0;
    }

   
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell=nil;
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSString *topicStr=[[[self.topicsArray objectAtIndex:indexPath.row] files] objectAtIndex:0];
    topicStr=[topicStr stringByReplacingOccurrencesOfString:@".pdf" withString:@""];
    topicStr = [UIAPPDelegate removeZZZ:topicStr];
    cell.textLabel.text=topicStr;

    
    //cell.textLabel.text=[[[self.topicsArray objectAtIndex:indexPath.row] files] objectAtIndex:0];
    
    
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    
    return cell;
}


 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 


 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 
         PSPDFBookmarkParser *bookmarkparser=[[self.topicsArray objectAtIndex:indexPath.row] bookmarkParser];
         NSString *str = [[[self.topicsArray objectAtIndex:indexPath.row] files] objectAtIndex:0];
         // remove the bookmarked pdf
         
         [bookmarkparser removeBookmarkForPage:0];
         // remove bookmark from coredata
         [UIAPPDelegate removeBookmark:str];
         
         // fetch new updated bookmarked
         self.bookmarkArray=  [UIAPPDelegate fetchBookmarks];
         // reload table
         [self.bookmarkTable reloadData];
     [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadGrid"
                                                         object:nil
                                                       userInfo:nil];
     
     
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
     
 }
 

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"selectBookmark"
                                                        object:[self.topicsArray objectAtIndex:indexPath.row]
                                                      userInfo:nil];
    

//           VideoDetailController *detail=[[VideoDetailController alloc] initWithNibName:@"VideoDetailController" bundle:nil];
//        detail.videoDetailDict =[self.VideoDetailArray objectAtIndex:indexPath.row];
//        [self.navigationController pushViewController:detail animated:YES];
   }

-(IBAction)cancelBtn:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"cancelpopover"
                                                        object:nil
                                                      userInfo:nil];

    
}

- (IBAction)EditTable:(id)sender{
    if(self.editing)
    {
        [super setEditing:NO animated:NO];
        [self.bookmarkTable setEditing:NO animated:NO];
        [self.bookmarkTable reloadData];
        // [Edit setImage:[UIImage imageNamed:@"edit.png"] forState:normal];
        
        [self.editButton setTitle:@"Edit"];
        //[self.navigationItem.rightBarButtonItem setStyle:UIBarButtonItemStylePlain];
        
    }
    else
    {
        [super setEditing:YES animated:YES];
        [self.bookmarkTable setEditing:YES animated:YES];
        [self.bookmarkTable reloadData];
        // [Edit setImage:[UIImage imageNamed:@"done.png"] forState:normal];
        
        [self.editButton setTitle:@"Done"];
        //[self.navigationItem.rightBarButtonItem setStyle:UIBarButtonItemStyleDone];
        
        // [self doneTabbed];
        
    }
    
    
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UISearchBarDelegate

//- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
//    [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionAllowUserInteraction animations:^{
//        searchBar.alpha = 1.f;
//    } completion:NULL];
//}
//
//- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
//    [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionAllowUserInteraction animations:^{
//        searchBar.alpha = 0.5f;
//    } completion:NULL];
//}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.topicsArray = nil;
    
    
    [self.bookmarkTable reloadData];
    
    //[self updateGrid];
    //self.collectionView.contentOffset = CGPointMake(0, -self.collectionView.contentInset.top);
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
