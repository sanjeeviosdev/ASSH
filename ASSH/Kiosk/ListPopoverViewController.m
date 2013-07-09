//
//  ListPopoverViewController.m
//  ASSH
//
//  Created by Sanjeev Jha on 13/05/13.
//  Copyright (c) 2013 ASSH. All rights reserved.
//

#import "ListPopoverViewController.h"
#import "ASSHAppDelegate.h"

@interface ListPopoverViewController ()

@end

@implementation ListPopoverViewController

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
    
    if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
    {
        self.table.frame=CGRectMake(0, 0, 450, 910);
    }
    else
    {
    
        self.table.frame=CGRectMake(0, 0, 450, 650);
    }

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
           
        if ([self.topicsArray count]==0) {
            
            return 0;
        }
    else
    {
        
        return [self.topicsArray count];
        
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
    
    
    
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    
    return cell;
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"selectTopic"
                                                        object:[self.topicsArray objectAtIndex:indexPath.row]
                                                      userInfo:nil];
    
    
    //           VideoDetailController *detail=[[VideoDetailController alloc] initWithNibName:@"VideoDetailController" bundle:nil];
    //        detail.videoDetailDict =[self.VideoDetailArray objectAtIndex:indexPath.row];
    //        [self.navigationController pushViewController:detail animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
