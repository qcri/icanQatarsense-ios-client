//
//  DashboardViewController.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 04/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PieChartView.h"
#import "BarChartView.h"
#import <CoreLocation/CoreLocation.h>

@interface DashboardViewController : UIViewController <PieChartViewDelegate, PieChartViewDataSource, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *previousButton;
@property (weak, nonatomic) IBOutlet UIButton *dateValueButton;
@property (weak, nonatomic) IBOutlet UIImageView *stepBgImageView;
@property (weak, nonatomic) IBOutlet UILabel *stepValueLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeValueLabel;
@property (weak, nonatomic) PieChartView * pieChartView;

@property (weak, nonatomic) IBOutlet BarChartView *barChartView;

//Methods
- (IBAction)changeDate:(id)sender;
- (IBAction)dateValueButtonTap:(id)sender;

-(void)setupView;
-(void)downloadData;

@end
