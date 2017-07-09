//
//  ContainerViewController.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 06/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginViewController.h"

@interface ContainerViewController : UINavigationController <LoginViewControllerDelegate>

-(void)showLoginView;

@end
