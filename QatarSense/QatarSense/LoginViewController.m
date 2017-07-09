//
//  LoginViewController.m
//  QatarSense
//
//  Created by Ravi Chaudhary on 03/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import "LoginViewController.h"
#import "AppConfig.h"
#import "MBProgressHUD.h"
#import "UserInfo.h"
#import "NSURLConnectionWithId.h"
#import "HelperClass.h"
#import "KeychainItemWrapper.h"
#import "AppDelegate.h"


@interface LoginViewController ()

@end

@implementation LoginViewController
{
    NSMutableData * responseData;
    NSDictionary * userInfoDictionary;
    NSInteger statusCode;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    //Set delegates
    self.usernameTextField.delegate = self;
    self.passwordTextField.delegate = self;
    
    //Set appropriate background image as per screen size
    [self setBackgroundImage];
    
    //Set login bg image
    [self.loginBgImageView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"LoginBg.png"]]];
    
    //Set notifications on keyboard hide and show
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:@"UIKeyboardWillShowNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:@"UIKeyboardWillHideNotification"
                                               object:nil];
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


/*
 * @desc - Checks for the Email and Password fields validation.
 * @return - Bool value that indicates that the field is validated or not.
 */
-(BOOL)validateFields
{
    BOOL isValid = YES;
    
    //Set proper message in case of some field'value is missing
    if([self.usernameTextField.text length] <= 0 || [self.passwordTextField.text length] <= 0)
    {
        //Show message
        [HelperClass showToastMessage:kFieldValidationMessage forDuration:3.0f];
        
        isValid = NO;
    }
    
    return isValid;
}


/*
 * @desc - Closes the keyboard when view is touched
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //Hide keyboard
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
}


/*
 * @desc - Gets called when Login button is pressed. Sends login request to server.
 */
- (IBAction)submitButtonTap:(id)sender
{
    if([self validateFields])           //If Yes, proceed to login
    {
        //Hide keyboard
        [self.usernameTextField resignFirstResponder];
        [self.passwordTextField resignFirstResponder];
    
        //Sends login request to server
        [self sendLoginRequest:NO];
        
    }
}


/*
 * @desc - Sends login request to server
 */
-(void)sendLoginRequest:(BOOL)isDeviceChanged
{
    if(![HelperClass isNetworkAvailable])
    {
        //Show NoNetwork Message
        [HelperClass showToastMessage:kNoNetworkMessage forDuration:2.0f];
        return;
    }
    
    //Create url
    NSString * loginUrl = [NSString stringWithFormat:@"%@%@", kServerBaseUrl, isDeviceChanged ? kDeviceChangedLoginApi : kLoginApi];
    NSURL * url = [NSURL URLWithString:loginUrl];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    //Set http method as POST
    [request setHTTPMethod:@"POST"];
    
    //Set request headers
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    
    if(isDeviceChanged)
    {
        if(userInfoDictionary)
        {
            NSInteger userId = [[userInfoDictionary objectForKey:@"userId"] longValue];
            NSString * authToken = [userInfoDictionary objectForKey:@"authToken"];
            
            [request setValue:[NSString stringWithFormat:@"%ld", userId] forHTTPHeaderField:@"userId"];
            [request setValue:authToken forHTTPHeaderField:@"authToken"];
        }
    }
    else
    {
        [request setValue:self.usernameTextField.text forHTTPHeaderField:@"userName"];
        [request setValue:self.passwordTextField.text forHTTPHeaderField:@"password"];
    }
    
    //Get UDID from keychain if it's there, else create one and save to keychain
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"QSense" accessGroup:nil];
    NSString * udid = [keychainItem objectForKey:kSecAttrAccount];
    if(udid == nil || udid.length == 0)
    {
        udid = [[[UIDevice currentDevice] identifierForVendor] UUIDString]; // IOS 6 and higher
        [keychainItem setObject:udid forKey:kSecAttrAccount];
    }
    
    [request setValue:udid forHTTPHeaderField:@"permanentDeviceId"];
    [request setValue:[HelperClass gmtString] forHTTPHeaderField:@"timezone"];
    
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
    NSLog(@"%ld", statusCode);
    switch (statusCode) {
        case 401:    //Invalid login error
            //Show message
            [HelperClass showToastMessage:kInvalidLoginMessage forDuration:2.0f];
            
            break;
            
        default:
            break;
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
        userInfoDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
        NSLog(@"Response : %@", userInfoDictionary);

        if(userInfoDictionary)
        {
            BOOL isDeviceChanged = [[userInfoDictionary objectForKey:@"isDeviceChanged"] boolValue];
            
            if(isDeviceChanged)
            {
                //Show alert
                UIAlertView * alert = [[UIAlertView alloc]initWithTitle:kMultipleLoginTitle
                                                                message:kMultipleLoginMessage
                                                               delegate:self
                                                      cancelButtonTitle:@"No"
                                                      otherButtonTitles:@"Yes", nil];
                [alert show];
            }
            else
            {
                [self registerDeviceType];
                
                //Process user info
                [self processUserInfo : userInfoDictionary];
                
                //Setup essential key value pairs to user defaults
                [self setUserDefaults];
                
                //Call ViewController's delegate method to hide login view
                [self.delegate loginViewControllerDidClose:self];
            }
        }
        else
        {
            //Show message
            [HelperClass showToastMessage:kUnknownErrorMessage forDuration:2.0f];
        }
    }

    
}


-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    //Hide progress indicator
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if([error code]==-1009)
    {
        //Show message
        [HelperClass showToastMessage:kNoNetworkMessage forDuration:2.0f];
    }
    else if([error code]==-1003)
    {
        //Show message
        [HelperClass showToastMessage:kServerNotFound forDuration:2.0f];
    }
    else
    {
        //Show message
        [HelperClass showToastMessage:kUnknownErrorMessage forDuration:2.0f];
    }
}


-(void)processUserInfo : (NSDictionary *)userInfoDict
{
    //Store data in model
    UserInfo * userInfo = [[UserInfo alloc]init];
    userInfo.userId = [[userInfoDict objectForKey:@"userId"] longValue];
    userInfo.sessionId = [[userInfoDict objectForKey:@"sessionId"] longValue];
    userInfo.authToken = [userInfoDict objectForKey:@"authToken"];
    userInfo.userName = [userInfoDict objectForKey:@"userName"];
    userInfo.firstName = [userInfoDict objectForKey:@"firstName"];
    userInfo.lastName = [userInfoDict objectForKey:@"lastName"];
    userInfo.groupName = [userInfoDict objectForKey:@"groupName"];
    userInfo.roleName = [userInfoDict objectForKey:@"roleName"];
    
    //Set userInfo to app delegate object's property "userInfo"
    AppDelegate * delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    delegate.userInfo = userInfo;
    
    //Store data model in User defaults
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:userInfo] forKey:kUserInfoKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/*
 * @desc - Sets essential key value pairs to user defaults
 */
-(void)setUserDefaults
{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:[NSNumber numberWithBool:YES] forKey:kSensorEnabledKey];
    [userDefaults setValue:kDefaultChart forKey:kChartTypeKey];
    
    //Update last updated timestamp
    double currentTimestamp = floor([[NSDate date] timeIntervalSince1970] / 60.0) * 60.0;
    [userDefaults setObject:[NSNumber numberWithDouble:currentTimestamp] forKey:kLastUpdatedTimestampKeySleep];
    [userDefaults setObject:[NSNumber numberWithDouble:currentTimestamp] forKey:kLastUpdatedTimestampKeyWorkout];
    [userDefaults setObject:[NSNumber numberWithDouble:currentTimestamp] forKey:kLastUpdatedTimestampKeyDistance];
    [userDefaults setObject:[NSNumber numberWithDouble:currentTimestamp] forKey:kLastUpdatedTimestampKeyHeart];
    [userDefaults setObject:[NSNumber numberWithDouble:currentTimestamp] forKey:kLastUpdatedTimestampKeyFlights];
    [userDefaults setObject:[NSNumber numberWithDouble:currentTimestamp] forKey:kLastUpdatedTimestampKeySteps];
    
    [userDefaults synchronize];
}


#pragma mark UITextField Delegate Methods -

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}


- (BOOL)textField:(UITextField *) textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;
    
    NSUInteger newLength = oldLength - rangeLength + replacementLength;
    
    BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
    
    return newLength <= kLoginTextFieldMaxLength || returnKey;
}



#pragma mark Keyboard Hide/Show Observers -

- (void) keyboardWillShow:(NSNotification *)note {
    NSDictionary *userInfo = [note userInfo];
    CGSize kbSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    NSLog(@"Keyboard Height: %f Width: %f", kbSize.height, kbSize.width);
    
    // move the view up by 30 pts
    CGRect frame = self.view.frame;
    CGFloat shiftAmount = self.submitButton.frame.origin.y + self.submitButton.frame.size.height + 10 + kbSize.height - frame.size.height;
    if(shiftAmount > 0)
    {
        frame.origin.y = - shiftAmount;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame = frame;
    }];
}

- (void) keyboardWillHide:(NSNotification *)note {
    
    // move the view back to the origin
    CGRect frame = self.view.frame;
    frame.origin.y = 0;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame = frame;
    }];
}



#pragma mark - MISC

/*
 * @desc - Returns timezone string from date
 */
-(void)timeZoneWithDate : (NSDate *)date
{
    NSDateFormatter *localTimeZoneFormatter = [NSDateFormatter new];
    localTimeZoneFormatter.timeZone = [NSTimeZone localTimeZone];
    localTimeZoneFormatter.dateFormat = @"ZZZ";
    NSString *localTimeZoneOffset = [localTimeZoneFormatter stringFromDate:date];
    NSLog(@"%@",localTimeZoneOffset);
}


-(void)registerDeviceType
{
    if([HelperClass isNetworkAvailable])
    {
        //Create url
        NSString * registerDeviceUrl = [NSString stringWithFormat:@"%@%@", kServerBaseUrl, kRegisterDeviceApi];
        NSURL * url = [NSURL URLWithString:registerDeviceUrl];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        
        //Set http method as POST
        [request setHTTPMethod:@"POST"];
        
        //Set request headers
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
        [request setValue:@"true" forHTTPHeaderField:@"isStepCountSensorAvailable"];
        [request setValue:@"IPHONE" forHTTPHeaderField:@"deviceType"];

        if(userInfoDictionary)
        {
            NSInteger userId = [[userInfoDictionary objectForKey:@"userId"] longValue];
            NSString * authToken = [userInfoDictionary objectForKey:@"authToken"];
            NSInteger sessionId = [[userInfoDictionary objectForKey:@"sessionId"] longValue];
            
            [request setValue:[NSString stringWithFormat:@"%ld", userId] forHTTPHeaderField:@"userId"];
            [request setValue:authToken forHTTPHeaderField:@"authToken"];
            [request setValue:[NSString stringWithFormat:@"%ld", sessionId] forHTTPHeaderField:@"sessionId"];
        }
        
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse * response, NSData * data, NSError * error){
            if(!error)
            {
                NSInteger code = [(NSHTTPURLResponse *)response statusCode];
                NSLog(@"%ld", code);
                if (code == 200) {
                    NSError * parseError;
                    NSDictionary * responseDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&parseError];
                    NSLog(@"Response : %@", responseDict);
                    
                    if(responseDict)
                    {
                        BOOL isSuccess = [[responseDict objectForKey:@"success"] boolValue];
                        
                        if(isSuccess)
                        {
                            //Device registered successfully
                        }
                    }
                    
                }
            }
            
        }];
    }
}


#pragma mark - Memory Management

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - AlertView Delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //If Yes tapped
    if(buttonIndex == 1)
    {
        [self sendLoginRequest:YES];
    }
}

@end
