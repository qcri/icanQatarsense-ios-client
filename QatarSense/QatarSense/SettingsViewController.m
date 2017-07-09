//
//  SettingsViewController.m
//  QatarSense
//
//  Created by Ravi Chaudhary on 04/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import "SettingsViewController.h"
#import "AppConfig.h"
#import "SWRevealViewController.h"
#import "UserInfo.h"
#import "Sensor.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController
{
    NSArray * itemsArray;
    UIView * pickerContainer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //Static array for the time being
    itemsArray = [[NSArray alloc]initWithObjects:@"Pie", @"Bar", nil];
    
    //Set view's background color
//    self.view.backgroundColor = [UIColor colorWithRed:40/255.0f green:40/255.0f blue:40/255.0f alpha:1];
    
    //Set appropriate background image as per screen size
    [self setBackgroundImage];
    
    //Set sensor view bg image
    [self.sensorBgImageView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"LoginBg.png"]]];

    //Set chart type view bg image
    [self.chartTypeBgImageView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"LoginBg.png"]]];

    
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
    
    //Populate user name, sensor switch and chart type button
    [self populateView];
}

-(void)populateView
{
    //Populate user name, sensor switch and chart type button
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL sensorEnabled = [[userDefaults objectForKey:kSensorEnabledKey] boolValue];
    [self.sensorSwitch setOn:sensorEnabled];
    NSString * chartType = [userDefaults objectForKey:kChartTypeKey];
    [self.chartTypeButton setTitle:chartType forState:UIControlStateNormal];
    
    //Fetch UserInfo model from user defaults
    NSData * data = [[NSUserDefaults standardUserDefaults]objectForKey:kUserInfoKey];
    UserInfo * userInfo;
    if(data)
    {
        userInfo = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSString * fullName = [NSString stringWithFormat:@"%@ %@", [userInfo.firstName capitalizedString], [userInfo.lastName capitalizedString]];
        self.userNameLabel.text = fullName;
        
        [self.userNameLabel setHidden:NO];
    }
    else
    {
        [self.userNameLabel setHidden:YES];
    }
    
    //If user is a participant, then show sensorRow else do not
    if([userInfo.roleName isEqualToString:kRoleParticipant])
    {
        [self.sensorBgImageView setHidden:NO];
    }
    else
    {
        [self.sensorBgImageView setHidden:YES];
        [self.sensorBgImageView removeFromSuperview];
    }
}


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
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Action Methods

- (IBAction)sensorSwitchValueChanged:(id)sender {
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:[NSNumber numberWithBool:self.sensorSwitch.on] forKey:kSensorEnabledKey];
    [userDefaults synchronize];
    
    Sensor * sensor = [Sensor sharedInstance];
    if(self.sensorSwitch.on)
    {
        [sensor startSensor];
    }
    else
    {
        [sensor stopSensor];
        
//        [sensor addSensingDisabledRecordAt:[NSDate date]];
    }
}

- (IBAction)chartTypeViewTap:(id)sender {
    [self togglePicker];
}

- (IBAction)chartTypeButtonTap:(id)sender {
    
    [self togglePicker];
}

#pragma mark - Picker Methods

-(void)togglePicker
{
    if(pickerContainer == nil)
    {
        [self createPickerView];
    }

    [UIView animateWithDuration:0.3f animations:^(){
    
        CGRect rect = pickerContainer.frame;
        
        rect.origin.y = (rect.origin.y >= self.view.frame.size.height) ? self.view.frame.size.height - rect.size.height : self.view.frame.size.height;
        
        pickerContainer.frame = rect;
    }];
    
}

-(void)createPickerView
{
    UIView * view = [[UIView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 246)];
    pickerContainer = view;
    pickerContainer.backgroundColor = [UIColor colorWithRed:210/255.0f green:210/255.0f blue:210/255.0f alpha:1];
    
    UIToolbar * toolBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, pickerContainer.frame.size.width, 44)];
    [pickerContainer addSubview:toolBar];


    UIBarButtonItem * flex = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];

    UIBarButtonItem * doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(togglePicker)];
    
    [toolBar setItems:[NSArray arrayWithObjects:flex, doneButton, nil]];
    
    UIPickerView * pickerView = [[UIPickerView alloc]initWithFrame:CGRectMake(0, 44, self.view.frame.size.width, 216)];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    [pickerContainer addSubview:pickerView];
    
    //Select last selected value in picker view
    NSInteger index = [itemsArray indexOfObject:[self.chartTypeButton titleForState:UIControlStateNormal]];
    NSLog(@"%ld", index);
    [pickerView selectRow:index inComponent:0 animated:NO];
    
    [self.view addSubview:pickerContainer];
}


#pragma mark - Picker view delegate methods

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [itemsArray count];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [itemsArray objectAtIndex:row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString * chartType = [itemsArray objectAtIndex:row];
    [[NSUserDefaults standardUserDefaults] setValue:chartType forKey:kChartTypeKey];
    [self.chartTypeButton setTitle:chartType forState:UIControlStateNormal];
}

@end
