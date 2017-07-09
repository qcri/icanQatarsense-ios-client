//
//  DashboardViewController.m
//  QatarSense
//
//  Created by Ravi Chaudhary on 04/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import "DashboardViewController.h"
#import "SWRevealViewController.h"
#import "AppConfig.h"
#import "SWRevealViewController.h"
#import "UserInfo.h"
#import "MenuTableViewController.h"
#import "MBProgressHUD.h"
#import "HelperClass.h"
#import "ContainerViewController.h"
#import "Activity.h"
#import "Sensor.h"
#import "AppDelegate.h"


@interface DashboardViewController ()

@end

@implementation DashboardViewController
{
    NSString * authToken;
    NSInteger userId;
    NSMutableData * responseData;
    NSInteger statusCode;
    NSDate * selectedDateValue;
    NSDate * today;
    NSArray * activities;
    NSString * chartType;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        self.title = @"Dashboard";
        
        //line is just for test
        chartType = [[NSUserDefaults standardUserDefaults]objectForKey:kChartTypeKey];
        
    }
    return self;
}


//-(void)loadView
//{
//    }

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //Set view's background color
    //self.view.backgroundColor = [UIColor colorWithRed:40/255.0f green:40/255.0f blue:40/255.0f alpha:1];

    //Set appropriate background image as per screen size
    [self setBackgroundImage];
    
    //Set step count bg image
    [self.stepBgImageView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"LoginBg.png"]]];
    
    //Make menu button at top left working
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController )
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

    [self setupDateSelectorView];
    
    //If auth token is not available, show login view else setup view
    [self setupView];
    
    //Initialize chart based on chart type selected in settings
    if([chartType isEqualToString:@"Bar"])
    {
        BarChartView * barChartView = [[BarChartView alloc]initWithFrame:CGRectMake(0, 0, 0, 10)];
        barChartView.backgroundColor = [UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:200.0f/255.0f alpha:1];
        [self.scrollView addSubview:barChartView];
        self.barChartView = barChartView;
    }
    else
    {
        CGFloat chartWidth = self.scrollView.frame.size.width / 2 - 10;
        PieChartView * pieChartView = [[PieChartView alloc] initWithFrame:CGRectMake(0, 0, chartWidth, chartWidth)];
        pieChartView.delegate = self;
        pieChartView.datasource = self;
        [self.scrollView addSubview:pieChartView];
        self.pieChartView = pieChartView;
    }
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
        NSLog(@"SessionId = %ld", userInfo.sessionId);
        
        //Set userInfo to app delegate object's property "userInfo"
        AppDelegate * delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        delegate.userInfo = userInfo;

        
        //Set auth token and userId in a variable
        authToken = userInfo.authToken;
        userId = userInfo.userId;
        
        //Show user's full name on rear view's navigation bar
        MenuTableViewController * menuTableViewController = (MenuTableViewController *)((UINavigationController *)self.revealViewController.rearViewController).viewControllers[0];
        NSString * fullName = [NSString stringWithFormat:@"%@ %@", [userInfo.firstName capitalizedString], [userInfo.lastName capitalizedString]];
        [menuTableViewController setNavigationTitleViewWithText:fullName];
        
        //Download dashboard data from server
        NSLog(@"Download dashboard data");
        [self downloadData];
        
        //If user is a participant, start sensor
        if([userInfo.roleName isEqualToString:kRoleParticipant])
        {
            //Start sensing data
            Sensor * sensor = [Sensor sharedInstance];
            if(!sensor.isSensorRunning)
            {
                [sensor startSensor];
            }
        }
    }
    else
    {
        //Present login view modally
        [self.revealViewController.navigationController performSegueWithIdentifier:@"loginSegue" sender:nil];

    }
}



/*
 * @desc - Makes navigation bar as transparent
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
    [self.messageLabel setHidden:YES];
    
    //Clear step count
    self.stepValueLabel.text = @"0";
    
    //Remove all subviews from content view
    for (UIView * view in self.contentView.subviews) {
        if(view.tag != 1 && view.tag != 2)
        {
            [view removeFromSuperview];
        }
    }
    
    //Hide scroll view and reset scroll position
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
    [self.scrollView setHidden:YES];
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
    NSString * urlString = [NSString stringWithFormat:@"%@%@", kServerBaseUrl, kDashboardApi];
    NSURL * url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    //Set http method as POST
    [request setHTTPMethod:@"GET"];
    
    //Get inputDate string
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString * inputDate = [dateFormatter stringFromDate:selectedDateValue];
    
    //Set request headers
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%ld", userId] forHTTPHeaderField:@"userId"];
    [request setValue:authToken forHTTPHeaderField:@"authToken"];
    [request setValue:inputDate forHTTPHeaderField:@"inputDate"];
    [request setValue:[HelperClass gmtString] forHTTPHeaderField:@"timezoneId"];
    [request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    
    //Create connection and start to download data
    NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    
    //Show progress indicator
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
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
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if(statusCode == 200)
    {
        //Convert JSON response into a dictionary object
        NSError * error;
        NSArray * activitiesArray = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
        NSLog(@"Response : %@", activitiesArray);
        
        if(activitiesArray)
        {
            //Process user info
            [self processData : activitiesArray];
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
 * @desc - Processes dashboard data
 */
-(void)processData : (NSArray *)array
{
    NSMutableArray * activitiesArray = [[NSMutableArray alloc]init];
    
    for (NSDictionary * item in array) {
        
        NSString * subCategoryName = [item objectForKey:@"subCategoryName"];
        float value = [[item objectForKey:@"value1"] floatValue];
        
        if([subCategoryName isEqualToString:kSubCategoryStepCount])
        {
            self.stepValueLabel.text = [NSString stringWithFormat:@"%ld", [[item objectForKey:@"value1"] integerValue]];
        }
        else if([subCategoryName isEqualToString:kActiveTime])
        {
            if ((int)value > 0) {
                self.totalTimeLabel.text = [NSString stringWithFormat:@"%@ - ", [item objectForKey:@"subCategoryDisplayName"]];
                self.totalTimeValueLabel.text = [NSString stringWithFormat:@"%@", [item objectForKey:@"value1String"]];
                
            }
            else
            {
                self.totalTimeLabel.text = @"";
                self.totalTimeValueLabel.text = @"";
            }
            
        }
        else
        {
            Activity * activity = [[Activity alloc]init];
            activity.name = subCategoryName;
            activity.displayName = [item objectForKey:@"subCategoryDisplayName"];
            activity.colorCode = [item objectForKey:@"color"];
            activity.value = value;
            activity.valueString = [item objectForKey:@"value1String"];
            activity.percentageString = [item objectForKey:@"value1Percentage"];
            [activitiesArray addObject:activity];

        }
    }
    
    activities = activitiesArray;
    
    //Populate activities
    if([activitiesArray count] > 0)
    {
        [self.scrollView setHidden:NO];
        
        [self populateContentViewWithData:activitiesArray];
    }
    else
    {
        [self.scrollView setHidden:YES];
        
        //Show no data message
        [self.messageLabel setHidden:NO];
    }
    
    
    
}


-(void)populateContentViewWithData : (NSArray *)dataArray
{
    float x = 0;
    float y = 30;
    float labelHeight = 20;
    float margin = 6;
    float bulletWidth = 20;
    float bulletRightMargin = 30;
    for (Activity * activity in dataArray) {
        
        UIView * bulletView = [[UIView alloc]initWithFrame:CGRectMake(x, y, bulletWidth, bulletWidth)];
        NSLog(@"%d", [activity.colorCode intValue]);
        [bulletView setBackgroundColor:[HelperClass colorWithHexString:activity.colorCode]];
        [self.contentView addSubview:bulletView];
        
        x += bulletWidth + bulletRightMargin;
        
        UILabel * label = [[UILabel alloc]init];
        [label setFrame:CGRectMake(x, y, self.contentView.frame.size.width, labelHeight)];
        [label setFont:[UIFont fontWithName:@"Prototype" size:15.0f]];
        [label setTextColor:[UIColor colorWithRed:90/255.0f green:90/255.0f blue:90/255.0f alpha:1]];
        label.text = [NSString stringWithFormat:@"%@ - %@ - %@", activity.displayName, activity.valueString, activity.percentageString];
        [self.contentView addSubview:label];
        
        y += labelHeight + margin;
        x = 0;
    }
    
    //Change height constraint
    NSLayoutConstraint * heightConstraint = nil;
    NSArray * constraints = self.contentView.constraints;
    for (NSLayoutConstraint * constraint in constraints) {
        if ([constraint.identifier isEqualToString:@"contentViewHeight"]) {
            heightConstraint = constraint;
            break;
        }
    }
    
    if(heightConstraint)
    {
        heightConstraint.constant = y;
    }
    
    //Reload charts
    if([chartType isEqualToString:@"Pie"])
    {
        //Reload pie chart
        [self.pieChartView reloadData];
        
        //Set frame of pieChartView
        CGRect rect = self.pieChartView.frame;
        rect.origin.y = y + 10;
        rect.origin.x = (self.scrollView.frame.size.width - rect.size.width) / 2;
        
        self.pieChartView.frame = rect;
        
        [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width, rect.origin.y + rect.size.height + 10)];
    }
    else if([chartType isEqualToString:@"Bar"])
    {
        //Reload bar chart
        [self loadBarChartUsingArray];
        
        //Set frame of barChartView
        self.barChartView.frame = CGRectMake(0, y + 10, self.scrollView.frame.size.width, self.scrollView.frame.size.width - 50);
        CGRect rect = self.barChartView.frame;
        
        [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width, rect.origin.y + rect.size.height + 10)];
    }
    
    //Make scroll view scrollable always
    if(self.scrollView.contentSize.height <= self.scrollView.frame.size.height)
    {
        [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width, self.scrollView.frame.size.height + 1)];
    }
    
    
}



//#pragma mark - Navigation
//
//// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    // Get the new view controller using [segue destinationViewController].
//    // Pass the selected object to the new view controller.
//    
//}

#pragma mark - Date Selector Methods

-(void)setupDateSelectorView
{
    selectedDateValue = [NSDate date];
    today = [NSDate date];
    
    [self populateDateSelectorView];
    [self.nextButton setEnabled:NO];
}


- (IBAction)changeDate:(id)sender {
    NSInteger tag = ((UIButton *)sender).tag;
    
    NSInteger numberOfDays = [self numberOfDaysBetween:today and:selectedDateValue];
    BOOL flag;
    if(tag == 1)
    {
        flag = numberOfDays < kMaxDays;
        
        if (numberOfDays + 1 >= kMaxDays) {
            //disable next button
            [((UIButton *)sender) setEnabled:NO];
        }
        [self.previousButton setEnabled:YES];
    }
    else
    {
        flag = numberOfDays > -kMinDays;
        if (numberOfDays - 1 <= -kMinDays) {
            //disable prev button
            [((UIButton *)sender) setEnabled:NO];
        }
        [self.nextButton setEnabled:YES];
    }
    
    if(flag)
    {
        selectedDateValue = [selectedDateValue dateByAddingTimeInterval:tag * kNumberOfSecondsInDay];
        [self populateDateSelectorView];
    }
    
    //Download data for selected date
    [self downloadData];
}

- (IBAction)dateValueButtonTap:(id)sender {
    
    //Download data for selected date
    [self downloadData];
}

/*
 * @desc - Returns number of days between given dates
 */
-(NSInteger)numberOfDaysBetween : (NSDate *)date1 and:(NSDate *) date2
{
    NSTimeInterval secondsBetween = round([date2 timeIntervalSinceDate:date1]);
    
    NSInteger numberOfDays = secondsBetween / kNumberOfSecondsInDay;
    
    return numberOfDays;
}


-(void)populateDateSelectorView
{
    int numberOfDays = (int)[self numberOfDaysBetween:today and:selectedDateValue];
    
    NSString * title = @"";
    
    if (numberOfDays == 0){
        title = @"Today";
    }
    else if (numberOfDays == -1){
        title = @"Yesterday";
    }
    else if (numberOfDays < -1){
        title = [NSString stringWithFormat:@"%d days ago", abs(numberOfDays)];
    }
    else if (numberOfDays == 1){
        title = @"Tomorrow";
    }
    else if (numberOfDays > 1){
        title = [NSString stringWithFormat:@"%d days after", numberOfDays];
    }
    
    [self.dateValueButton setTitle:title forState:UIControlStateNormal];
}


#pragma mark -    PieChartViewDelegate

-(CGFloat)centerCircleRadius
{
    return 30;
}

#pragma mark - PieChartViewDataSource

-(int)numberOfSlicesInPieChartView:(PieChartView *)pieChartView
{
    return (int)[activities count];
}

-(UIColor *)pieChartView:(PieChartView *)pieChartView colorForSliceAtIndex:(NSUInteger)index
{
    return [HelperClass colorWithHexString:((Activity *)[activities objectAtIndex:index]).colorCode];
}

-(double)pieChartView:(PieChartView *)pieChartView valueForSliceAtIndex:(NSUInteger)index
{
    return [((Activity *)[activities objectAtIndex:index]).percentageString doubleValue];
}

-(NSString *)pieChartView:(PieChartView *)pieChartView titleForSliceAtIndex:(NSUInteger)index
{
    return ((Activity *)[activities objectAtIndex:index]).displayName;
}


#pragma mark - Bar Chart Setup

- (void)loadBarChartUsingArray {
    
    //Create arrays
    NSMutableArray * titles = [[NSMutableArray alloc]init];
    NSMutableArray * colors = [[NSMutableArray alloc]init];
    NSMutableArray * values = [[NSMutableArray alloc]init];
    NSMutableArray * labelColors = [[NSMutableArray alloc]init];
    
    //Populate arrays
    for (Activity * activity in activities) {
        [titles addObject:@""];
        [colors addObject:activity.colorCode];
        [values addObject:activity.percentageString];
        [labelColors addObject:activity.colorCode];
    }

    
    //Generate properly formatted data to give to the bar chart
    NSArray *array = [self.barChartView createChartDataWithTitles:titles
                                                  values:values
                                                  colors:colors
                                             labelColors:labelColors];
    
    //Set the Shape of the Bars (Rounded or Squared) - Rounded is default
    [self.barChartView setupBarViewShape:BarShapeRounded];
    
    //Set the Style of the Bars (Glossy, Matte, or Flat) - Glossy is default
    [self.barChartView setupBarViewStyle:BarStyleFlat];
    
    //Set the Drop Shadow of the Bars (Light, Heavy, or None) - Light is default
    [self.barChartView setupBarViewShadow:BarShadowNone];
    
    //Generate the bar chart using the formatted data
    [self.barChartView setDataWithArray:array
                      showAxis:DisplayBothAxes
                     withColor:[UIColor whiteColor]
       shouldPlotVerticalLines:YES];
}

@end
