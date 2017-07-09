//
//  LeaderboardItem.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 16/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LeaderboardItem : NSObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * displayName;
@property (nonatomic) float value;
@property (nonatomic) float minValue;
@property (nonatomic) float maxValue;
@property (nonatomic) float averageValue;
@property (nonatomic, strong) NSString * valueString;
@property (nonatomic) float valuePercentage;
@property (nonatomic, strong) NSString * minString;
@property (nonatomic, strong) NSString * maxString;
@property (nonatomic, strong) NSString * averageString;
@property (nonatomic) NSInteger sortOrder;

@end