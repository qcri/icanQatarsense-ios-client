//
//  LeaderboardViewController.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 04/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LeaderboardViewController : UIViewController <UITabBarControllerDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

//Methods
- (IBAction)valueChanged:(id)sender;
-(void)downloadData;

@end
