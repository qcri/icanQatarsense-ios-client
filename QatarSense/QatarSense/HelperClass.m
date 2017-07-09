//
//  HelperClass.m
//  QatarSense
//
//  Created by Ravi Chaudhary on 08/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import "HelperClass.h"
#import "Reachability.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "AppConfig.h"
#import "ContainerViewController.h"
#import <HealthKit/HealthKit.h>

@implementation HelperClass


+ (NSString *)htmlFromBodyString:(NSString *)htmlBodyString
                        textFont:(UIFont *)font
                       textColor:(UIColor *)textColor
{
    int numComponents = (int)CGColorGetNumberOfComponents([textColor CGColor]);
    
    NSAssert(numComponents == 4 || numComponents == 2, @"Unsupported color format");
    
    // E.g. FF00A5
    NSString *colorHexString = nil;
    
    const CGFloat *components = CGColorGetComponents([textColor CGColor]);
    
    if (numComponents == 4)
    {
        unsigned int red = components[0] * 255;
        unsigned int green = components[1] * 255;
        unsigned int blue = components[2] * 255;
        colorHexString = [NSString stringWithFormat:@"%02X%02X%02X", red, green, blue];
    }
    else
    {
        unsigned int white = components[0] * 255;
        colorHexString = [NSString stringWithFormat:@"%02X%02X%02X", white, white, white];
    }
    
    NSString *HTML = [NSString stringWithFormat:@"<html>\n"
                      "<head>\n"
                      "<style type=\"text/css\">\n"
                      "body {font-family: \"%@\"; font-size: %@; color:#%@;}\n"
                      "</style>\n"
                      "</head>\n"
                      "<body>%@</body>\n"
                      "</html>",
                      font.familyName, @(font.pointSize), colorHexString, htmlBodyString];
    
    return HTML;
}


+(BOOL)isNetworkAvailable
{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    return (networkStatus != NotReachable);
}


/*
 * @desc - Shows toast message for specified duration in seconds
 */
+(void) showToastMessage : (NSString *)message forDuration : (NSTimeInterval)duration
{
    AppDelegate * delgate = [[UIApplication sharedApplication]delegate];
    MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:delgate.window animated:YES];
    hud.label.text = message;
    hud.mode = MBProgressHUDModeText;
    [hud hideAnimated:YES afterDelay:3.0f];
}


+(UIColor *)colorWithHexString:(NSString*)hex
{
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];
    
    // strip 0X if it appears
    
    // strip # if it appears
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    else if ([cString hasPrefix:@"0X"])
        cString = [cString substringFromIndex:2];
    
    if ([cString length] != 6) return  [UIColor grayColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}


+(NSString *)getActivityTypeString : (int)activityType
{
    NSString * result = @"";
    
    switch (activityType) {
        case HKWorkoutActivityTypeAmericanFootball :
            result = kSubCategoryAmericanFootball;
            break;
        case HKWorkoutActivityTypeArchery :
            result = kSubCategoryArchery;
            break;
        case HKWorkoutActivityTypeAustralianFootball :
            result = kSubCategoryAustralianFootball;
            break;
        case HKWorkoutActivityTypeBadminton :
            result = kSubCategoryBadminton;
            break;
        case HKWorkoutActivityTypeBaseball :
            result = kSubCategoryBaseball;
            break;
        case HKWorkoutActivityTypeBasketball :
            result = kSubCategoryBasketball;
            break;
        case HKWorkoutActivityTypeBowling :
            result = kSubCategoryBowling;
            break;
        case HKWorkoutActivityTypeBoxing :
            result = kSubCategoryBoxing;
            break;
        case HKWorkoutActivityTypeClimbing :
            result = kSubCategoryClimbing;
            break;
        case HKWorkoutActivityTypeCricket :
            result = kSubCategoryCricket;
            break;
        case HKWorkoutActivityTypeCrossTraining :
            result = kSubCategoryCrossTraining;
            break;
        case HKWorkoutActivityTypeCurling :
            result = kSubCategoryCurling;
            break;
        case HKWorkoutActivityTypeCycling :
            result = kSubCategoryCycling;
            break;
        case HKWorkoutActivityTypeDance :
            result = kSubCategoryDance;
            break;
        case HKWorkoutActivityTypeDanceInspiredTraining :
            result = kSubCategoryDanceTraining;
            break;
        case HKWorkoutActivityTypeElliptical :
            result = kSubCategoryElliptical;
            break;
        case HKWorkoutActivityTypeEquestrianSports :
            result = kSubCategoryEquestrianSports;
            break;
        case HKWorkoutActivityTypeFencing :
            result = kSubCategoryFencing;
            break;
        case HKWorkoutActivityTypeFishing :
            result = kSubCategoryFishing;
            break;
        case HKWorkoutActivityTypeFunctionalStrengthTraining :
            result = kSubCategoryFunctional;
            break;
        case HKWorkoutActivityTypeGolf :
            result = kSubCategoryGolf;
            break;
        case HKWorkoutActivityTypeGymnastics :
            result = kSubCategoryGymnastics;
            break;
        case HKWorkoutActivityTypeHandball :
            result = kSubCategoryHandball;
            break;
        case HKWorkoutActivityTypeHiking :
            result = kSubCategoryHiking;
            break;
        case HKWorkoutActivityTypeHockey :
            result = kSubCategoryHockey;
            break;
        case HKWorkoutActivityTypeHunting :
            result = kSubCategoryHunting;
            break;
        case HKWorkoutActivityTypeLacrosse :
            result = kSubCategoryLacrosse;
            break;
        case HKWorkoutActivityTypeMartialArts :
            result = kSubCategoryMartialArts;
            break;
        case HKWorkoutActivityTypeMindAndBody :
            result = kSubCategoryMindAndBody;
            break;
        case HKWorkoutActivityTypeMixedMetabolicCardioTraining :
            result = kSubCategoryCardioTraining;
            break;
        case HKWorkoutActivityTypePaddleSports :
            result = kSubCategoryPaddleSports;
            break;
        case HKWorkoutActivityTypePlay :
            result = kSubCategoryPlay;
            break;
        case HKWorkoutActivityTypePreparationAndRecovery :
            result = kSubCategoryPreparation;
            break;
        case HKWorkoutActivityTypeRacquetball :
            result = kSubCategoryRacquetball;
            break;
        case HKWorkoutActivityTypeRowing :
            result = kSubCategoryRowing;
            break;
        case HKWorkoutActivityTypeRugby :
            result = kSubCategoryRugby;
            break;
        case HKWorkoutActivityTypeRunning :
            result = kSubCategoryRun;
            break;
        case HKWorkoutActivityTypeSailing :
            result = kSubCategorySailing;
            break;
        case HKWorkoutActivityTypeSkatingSports :
            result = kSubCategorySkatingSports;
            break;
        case HKWorkoutActivityTypeSnowSports :
            result = kSubCategorySnowSports;
            break;
        case HKWorkoutActivityTypeSoccer :
            result = kSubCategorySoccer;
            break;
        case HKWorkoutActivityTypeSoftball :
            result = kSubCategorySoftball;
            break;
        case HKWorkoutActivityTypeSquash :
            result = kSubCategorySquash;
            break;
        case HKWorkoutActivityTypeStairClimbing :
            result = kSubCategoryStairClimbing;
            break;
        case HKWorkoutActivityTypeSurfingSports :
            result = kSubCategorySurfingSports;
            break;
        case HKWorkoutActivityTypeSwimming :
            result = kSubCategorySwimming;
            break;
        case HKWorkoutActivityTypeTableTennis :
            result = kSubCategoryTableTennis;
            break;
        case HKWorkoutActivityTypeTennis :
            result = kSubCategoryTennis;
            break;
        case HKWorkoutActivityTypeTrackAndField :
            result = kSubCategoryTrackAndField;
            break;
        case HKWorkoutActivityTypeTraditionalStrengthTraining :
            result = kSubCategoryTraditional;
            break;
        case HKWorkoutActivityTypeVolleyball :
            result = kSubCategoryVolleyball;
            break;
        case HKWorkoutActivityTypeWalking :
            result = kSubCategoryWalk;
            break;
        case HKWorkoutActivityTypeWaterFitness :
            result = kSubCategoryWaterFitness;
            break;
        case HKWorkoutActivityTypeWaterPolo :
            result = kSubCategoryWaterPolo;
            break;
        case HKWorkoutActivityTypeWaterSports :
            result = kSubCategoryWaterSports;
            break;
        case HKWorkoutActivityTypeWrestling :
            result = kSubCategoryWrestling;
            break;
        case HKWorkoutActivityTypeYoga :
            result = kSubCategoryYoga;
            break;
    }
    return result;
}

/*
 * @desc - Returns current timezone's GMT string like "GMT+05:30"
 */
+(NSString *)gmtString
{
    NSDateFormatter * df =[[NSDateFormatter alloc]init];
    [df setDateFormat:@"ZZZ"];
    NSString * gmt = [df stringFromDate:[NSDate date]];
    NSMutableString * formattedString = [NSMutableString stringWithString:gmt];
    [formattedString insertString:@":" atIndex:3];
    [formattedString insertString:@"GMT" atIndex:0];
    return formattedString;
}


+(void)showSessionExpiredMessage
{
    AppDelegate * delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(!delegate.userInfo)
    {
        return;
    }
    
    //Present login view
    [((ContainerViewController *)delegate.window.rootViewController) showLoginView];
    
    //Show session expired message
    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:nil
                                                    message:kSessionExpiredMessage
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
