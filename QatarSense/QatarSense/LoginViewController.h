//
//  LoginViewController.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 03/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LoginViewController;

@protocol LoginViewControllerDelegate <NSObject>

-(void) loginViewControllerDidClose: (LoginViewController *)loginViewController;

@end


@interface LoginViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) id <LoginViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField * passwordTextField;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UIImageView *loginBgImageView;

//Methods
- (IBAction)submitButtonTap:(id)sender;

@end
