//
//  ContainerViewController.m
//  QatarSense
//
//  Created by Ravi Chaudhary on 06/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import "ContainerViewController.h"
#import "SWRevealViewController.h"
#import "DashboardViewController.h"
#import "MenuTableViewController.h"
#import "Sensor.h"
#import "AppConfig.h"
#import "AppDelegate.h"
#import "UserInfo.h"

@interface ContainerViewController ()

@end

@implementation ContainerViewController
{
    NSString * authToken;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
 * @desc - Shows login view when session is expired
 */
-(void)showLoginView
{
    //Present login view modally
    [self performSegueWithIdentifier:@"loginSegue" sender:nil];
    
    //Clear user defaults
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:nil forKey:kUserInfoKey];
    [userDefaults setValue:nil forKey:kSensorEnabledKey];
    [userDefaults setValue:nil forKey:kChartTypeKey];
    [userDefaults synchronize];
    
    //Set nil to app delegate object's property "userInfo"
    AppDelegate * delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSString * userRole = ((UserInfo *)delegate.userInfo).roleName;
    delegate.userInfo = nil;
    
    //If user is a participant, stop sensor
    if([userRole isEqualToString:kRoleParticipant])
    {
        //Stop sensor
        Sensor * sensor = [Sensor sharedInstance];
        [sensor stopSensor];
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    ((LoginViewController *)((UINavigationController *)segue.destinationViewController).topViewController).delegate = self;
}


#pragma mark - LoginViewController Delegate
-(void)loginViewControllerDidClose:(LoginViewController *)loginViewController{
    
    //Dissmiss Login view controller
    [self dismissViewControllerAnimated:YES completion:nil];
    
    //Show user's full name on rear view's navigation bar and start downloading dashboad data
    SWRevealViewController * revealController = (SWRevealViewController *)self.viewControllers[0];
    
    MenuTableViewController * menuTableViewController = (MenuTableViewController *)((UINavigationController *)revealController.rearViewController).viewControllers[0];

    //Always show dashboard when user logs in
    [menuTableViewController performSegueWithIdentifier:@"dashboardSegue" sender:nil];
}



@end
