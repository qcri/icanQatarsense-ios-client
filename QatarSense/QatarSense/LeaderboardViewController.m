//
//  LeaderboardViewController.m
//  QatarSense
//
//  Created by Ravi Chaudhary on 04/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import "LeaderboardViewController.h"
#import "SWRevealViewController.h"
#import "AppConfig.h"
#import "LeaderboardCell.h"
#import "HelperClass.h"
#import "MBProgressHUD.h"
#import "ContainerViewController.h"
#import "UserInfo.h"
#import "LeaderboardItem.h"

@interface LeaderboardViewController ()

@end

@implementation LeaderboardViewController
{
    NSString * authToken;
    NSInteger userId;
    NSMutableData * responseData;
    NSInteger statusCode;
    NSArray * leaderboardItems;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //Set view's background color
    self.view.backgroundColor = [UIColor whiteColor];
    
    //Set table view's background color
    self.tableView.backgroundColor = [UIColor clearColor];
    
    //Set appropriate background image as per screen size
    [self setBackgroundImage];
    
    //Make menu button at top left working
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController)
    {
        [self.menuButton setTarget:revealViewController];
        [self.menuButton setAction:@selector(revealToggle:)];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    //Set title view of navigation item
    UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,40,320,40)];
    titleLabel.textAlignment = NSTextAlignmentRight;
    titleLabel.font = [UIFont fontWithName:@"Prototype" size:17.0f];
    titleLabel.textColor = [UIColor colorWithRed:247/255.0f green:210/255.0f blue:0 alpha:1];
    titleLabel.text = self.title;
    self.navigationItem.titleView = titleLabel;
    
    //Make navigation bar transparent
    [self presentTransparentNavigationBar];

    self.segmentedControl.layer.cornerRadius = 4;
    
    [self setupView];
}


/*
 * @desc - If auth token is not available, shows login view, else sets up view
 */
-(void)setupView
{
    //Fetch UserInfo model from user defaults
    NSData * data = [[NSUserDefaults standardUserDefaults]objectForKey:kUserInfoKey];
    UserInfo * userInfo = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    //If auth token present
    if(userInfo && userInfo.authToken)
    {
        //Set auth token and userId in a variable
        authToken = userInfo.authToken;
        userId = userInfo.userId;
        
        //Download leaderboard data from server
        NSLog(@"Download leaderboard data");
        [self downloadData];
    }
    else
    {
        //Present login view modally
        [self.revealViewController.navigationController performSegueWithIdentifier:@"loginSegue" sender:nil];
        
    }
}

/*
 * #desc - Makes navigation bar transparent
 */
- (void)presentTransparentNavigationBar
{
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
}



/*
 * @desc - Sets appropriate background image as per screen size
 */
-(void)setBackgroundImage
{
    if(kScreenHeight == 568.0f)
    {
        self.backgroundImageView.image = [UIImage imageNamed:@"Background-568h@2x.png"];
    }
    else if(kScreenHeight == 667.0f)
    {
        self.backgroundImageView.image = [UIImage imageNamed:@"Background-667h@2x.png"];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
 * @desc - Resets view
 */
-(void)resetView
{
    [self.tableView setHidden:YES];
    
    [self.messageLabel setHidden:YES];
}


/*
 * @desc - Sends request to download dashboard data
 */
-(void)downloadData
{
    //Reset view
    [self resetView];
    
    if(![HelperClass isNetworkAvailable])
    {
        //Show no data message
        [self.messageLabel setHidden:NO];
        
        //Show NoNetwork Message
        [HelperClass showToastMessage:kNoNetworkMessage forDuration:2.0f];
        return;
    }
    
    //Create url
    NSString * urlString = [NSString stringWithFormat:@"%@%@", kServerBaseUrl, kLeaderboardApi];
    NSURL * url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    //Set http method as POST
    [request setHTTPMethod:@"GET"];
    
    //Get inputDate string
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString * inputDate = [dateFormatter stringFromDate:[NSDate date]];
    
    //Set request headers
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%ld", userId] forHTTPHeaderField:@"userId"];
    [request setValue:authToken forHTTPHeaderField:@"authToken"];
    [request setValue:inputDate forHTTPHeaderField:@"inputDate"];
    [request setValue:[HelperClass gmtString] forHTTPHeaderField:@"timezoneId"];
    [request setValue:[NSString stringWithFormat:@"%d", [self noOfDaysBasedOnSelectedSegment]] forHTTPHeaderField:@"noOfdays"];
    [request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    
    //Create connection and start to download data
    NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    
    //Show progress indicator
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}


/*
 * @desc - Returns no of days based on selected segment in segmented control
 */
-(int)noOfDaysBasedOnSelectedSegment
{
    int noOfDays = 0;
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0:
            noOfDays = 1;
            break;
        case 1:
            noOfDays = 7;
            break;
        case 2:
            noOfDays = 30;
            break;
    }
    
    return noOfDays;
}


#pragma mark - NSURLConnection Delegate Methods

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //Create responseData to store the response
    NSMutableData * mutableData = [[NSMutableData alloc]init];
    responseData = mutableData;
    
    //Get status code
    statusCode = [(NSHTTPURLResponse *)response statusCode];
    NSLog(@"%ld", (long)statusCode);
    if (statusCode == 401)     //session expired error
    {
        [HelperClass showSessionExpiredMessage];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //Append all of the response to the responseData object
    [responseData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //Hide progress indicator
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if(statusCode == 200)
    {
        //Convert JSON response into a dictionary object
        NSError * error;
        NSArray * itemsArray = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
        NSLog(@"Response : %@", itemsArray);
        
        if(itemsArray)
        {
            //Process user info
            [self processData : itemsArray];
        }
        else
        {
            //Show no data message
            [self.messageLabel setHidden:NO];
            
            //Show message
            [HelperClass showToastMessage:kUnknownErrorMessage forDuration:2.0f];
        }
    }
    
    
}


-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    //Hide progress indicator
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    //Show no data message
    [self.messageLabel setHidden:NO];
    
    if([error code]==-1009)
    {
        //Show message
        [HelperClass showToastMessage:kNoNetworkMessage forDuration:2.0f];
    }
    else
    {
        //Show message
        [HelperClass showToastMessage:kUnknownErrorMessage forDuration:2.0f];
    }
}

/*
 * @desc - Processes leaderboard data
 */
-(void)processData : (NSArray *)array
{
    NSMutableArray * itemsArray = [[NSMutableArray alloc]init];
    
    //Create an array of leaderboard items
    for (NSDictionary * dictionary in array) {
        
        LeaderboardItem * item = [[LeaderboardItem alloc]init];
        item.name = [dictionary objectForKey:@"subCategoryName"];
        item.displayName = [dictionary objectForKey:@"subCategoryDisplayName"];
        item.value = [[dictionary objectForKey:@"userDuration"] floatValue];
        item.minValue = [[dictionary objectForKey:@"min"] floatValue];
        item.maxValue = [[dictionary objectForKey:@"max"] floatValue];
        item.averageValue = [[dictionary objectForKey:@"average"] floatValue];
        item.valueString = [dictionary objectForKey:@"userDurationString"];
        item.valuePercentage = [[dictionary objectForKey:@"userDurationPercentage"] floatValue];
        item.minString = [dictionary objectForKey:@"minString"];
        item.maxString = [dictionary objectForKey:@"maxString"];
        item.averageString = [dictionary objectForKey:@"averageString"];
        item.sortOrder = [[dictionary objectForKey:@"sortOrder"] intValue];
        [itemsArray addObject:item];
    }
    
    //Sort array based on sort order
    
    leaderboardItems = itemsArray;
    
    //Populate data on leaderboard view
    [self.tableView reloadData];
    
    [self.tableView setHidden:NO];
    
    if([leaderboardItems count] == 0)
    {
        //Show no data message
        [self.messageLabel setHidden:NO];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [leaderboardItems count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"LeaderboardCell";
    LeaderboardCell *cell = (LeaderboardCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    LeaderboardItem * item = [leaderboardItems objectAtIndex:indexPath.row];
    
    //Populate cell
    cell.activityNameLabel.text = [NSString stringWithFormat:@"%@", item.displayName];
    cell.minLabel.text = [NSString stringWithFormat:@"%@", item.minString];
    cell.maxLabel.text = [NSString stringWithFormat:@"%@", item.maxString];
    cell.averageLabel.text = [NSString stringWithFormat:@"%@", item.averageString];
    cell.maxLabel.text = [NSString stringWithFormat:@"%@", item.maxString];
    cell.activityValueLabel.text = [NSString stringWithFormat:@"%@", item.valueString];
    cell.activityPerLabelLeft.text = cell.activityPerLabelRight.text = [NSString stringWithFormat:@"%.0f%%", item.valuePercentage];
    
    //Change width constraint
    NSLayoutConstraint * widthConstraint = nil;
    NSArray * constraints = cell.activityView.constraints;
    for (NSLayoutConstraint * constraint in constraints) {
        if ([constraint.identifier isEqualToString:@"activityViewWidth"]) {
            widthConstraint = constraint;
            break;
        }
    }
    
    CGFloat width = 0;
    
    if(widthConstraint)
    {
        CGFloat activityViewMaxWidth = self.tableView.frame.size.width - 24;
        width = activityViewMaxWidth * item.valuePercentage / 100;
        if(width > activityViewMaxWidth)
        {
            width = activityViewMaxWidth;
        }

        widthConstraint.constant = width;
    }
    
    //Show only either of percentage labels
    BOOL showRightLabel = item.valuePercentage < 50;
    [cell.activityPerLabelRight setHidden:!showRightLabel];
    [cell.activityPerLabelLeft setHidden:showRightLabel];

    return cell;
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)valueChanged:(id)sender {
    //Download leaderboard data from server
    [self downloadData];
}

@end
