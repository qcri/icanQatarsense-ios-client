//
//  LeaderboardCell.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 15/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LeaderboardCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIView * activityView;
@property (weak, nonatomic) IBOutlet UILabel *activityNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *minLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxLabel;
@property (weak, nonatomic) IBOutlet UILabel *averageLabel;
@property (weak, nonatomic) IBOutlet UILabel *activityValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *activityPerLabelLeft;
@property (weak, nonatomic) IBOutlet UILabel *activityPerLabelRight;

@end
