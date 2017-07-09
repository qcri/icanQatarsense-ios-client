//
//  Activity.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 12/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Activity : NSObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * displayName;
@property (nonatomic) float value;
@property (nonatomic, strong) NSString * valueString;
@property (nonatomic, strong) NSString * percentageString;
@property (nonatomic, strong) NSString * colorCode;

@end
