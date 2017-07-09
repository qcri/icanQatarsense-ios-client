//
//  HelperClass.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 08/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HelperClass : NSObject

//Class methods
+ (NSString *)htmlFromBodyString:(NSString *)htmlBodyString textFont:(UIFont *)font textColor:(UIColor *)textColor;
+(BOOL)isNetworkAvailable;
+(void) showToastMessage : (NSString *)message forDuration : (NSTimeInterval)duration;
+(UIColor*)colorWithHexString:(NSString*)hex;
+(NSString *)getActivityTypeString : (int)activityType;
+(NSString *)gmtString;
+(void)showSessionExpiredMessage;
@end
