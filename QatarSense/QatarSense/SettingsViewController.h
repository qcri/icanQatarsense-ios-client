//
//  SettingsViewController.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 04/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UIView *sensorBgImageView;
@property (weak, nonatomic) IBOutlet UIView *chartTypeBgImageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

@property (weak, nonatomic) IBOutlet UISwitch *sensorSwitch;
@property (weak, nonatomic) IBOutlet UIButton *chartTypeButton;

//Action Methods
- (IBAction)chartTypeButtonTap:(id)sender;
- (IBAction)sensorSwitchValueChanged:(id)sender;
- (IBAction)chartTypeViewTap:(id)sender;

@end
