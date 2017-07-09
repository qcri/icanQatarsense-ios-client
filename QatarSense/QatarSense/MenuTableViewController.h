//
//  MenuTableViewController.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 04/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MenuTableViewController : UITableViewController

@property(nonatomic, strong) NSString * tit;

-(void)setNavigationTitleViewWithText : (NSString *)text;

@end
