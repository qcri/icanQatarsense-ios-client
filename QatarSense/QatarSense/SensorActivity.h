//
//  SensorActivity.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 25/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SensorActivity : NSObject

@property (nonatomic, strong) NSString * date1;
@property (nonatomic, strong) NSString * date2;
@property (nonatomic, strong) NSString * category;
@property (nonatomic, strong) NSString * subCategory;
@property (nonatomic, strong) NSString * dateCreated;
@property (nonatomic, strong) NSString * dateModified;
@property (nonatomic) double timestamp;
@property (nonatomic, strong) NSString * timestampString;
@property (nonatomic, strong) NSString * field1;
@property (nonatomic, strong) NSString * field2;
@property (nonatomic, strong) NSString * field3;



@end