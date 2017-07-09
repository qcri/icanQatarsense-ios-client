//
//  MenuTableViewController.m
//  QatarSense
//
//  Created by Ravi Chaudhary on 04/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import "MenuTableViewController.h"
#import "DashboardViewController.h"
#import "LeaderboardViewController.h"
#import "SettingsViewController.h"
#import "HelpViewController.h"
#import "SWRevealViewController.h"

@interface MenuTableViewController ()

@end

@implementation MenuTableViewController
{
    NSArray * menuItems;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Static array for the time being
    menuItems = @[@"Dashboard", @"Leaderboard", @"Settings", @"Help"];
    
    //Set table view's background color
    self.tableView.backgroundColor = [UIColor colorWithRed:40/255.0f green:40/255.0f blue:40/255.0f alpha:1];
    
    //Set navigation bar color
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:40/255.0f green:40/255.0f blue:40/255.0f alpha:1];
    
    self.tit = @"Menu";
}


-(void)setNavigationTitleViewWithText : (NSString *)text
{
    //Set title view of navigation item
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,40,320,40)];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.font = [UIFont fontWithName:@"Prototype" size:22.0f];
    titleLabel.textColor = [UIColor colorWithRed:230/255.0f green:230/255.0f blue:230/255.0f alpha:1];
    titleLabel.text = text;
    self.navigationItem.titleView = titleLabel;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [menuItems count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * cellIdentifier = @"MenuCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(!cell)
    {
        //Create cell
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        
        cell.textLabel.font = [UIFont fontWithName:@"Prototype" size:16.0f];
        cell.textLabel.textColor = [UIColor colorWithRed:240/255.0f green:240/255.0f blue:240/255.0f alpha:1];
        cell.textLabel.highlightedTextColor = [UIColor colorWithRed:30/255.0f green:30/255.0f blue:30/255.0f alpha:1];
        cell.backgroundColor = [UIColor clearColor];
    }
    
    // Configure the cell...
    NSString * title = menuItems[indexPath.row];
    cell.textLabel.text = title;
    cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@Icon", title]];
    
    return cell;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 55.0f;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    NSString * itemName = menuItems[indexPath.row];
    if ([itemName isEqualToString:@"Dashboard"]) {
        [self performSegueWithIdentifier:@"dashboardSegue" sender:nil];
    }
    else if ([itemName isEqualToString:@"Leaderboard"]) {
        [self performSegueWithIdentifier:@"leaderboardSegue" sender:nil];
    }
    else if ([itemName isEqualToString:@"Settings"]) {
        [self performSegueWithIdentifier:@"settingsSegue" sender:nil];
    }
    else if ([itemName isEqualToString:@"Help"]) {
        [self performSegueWithIdentifier:@"helpSegue" sender:nil];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    // Set the title of navigation bar by using the menu items
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    UINavigationController * navController = segue.destinationViewController;
    [navController topViewController].title = [[menuItems objectAtIndex:indexPath.row] capitalizedString];
}


@end
