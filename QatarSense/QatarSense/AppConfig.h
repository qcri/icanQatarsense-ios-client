//
//  AppConfig.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 03/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kServerBaseUrl                   @"http://scdev5.qcri.org/qsense/"
//#define kServerBaseUrl                   @"http://172.16.5.94:8080/qsense/"
//#define kServerBaseUrl                   @"http://localhost:8080/qsense/"
//#define kServerBaseUrl                   @"http://192.168.1.101:8080/qsense/"

#define kLoginApi                        @"mobile-ws/mlogin/"
#define kLogActivitiesApi                @"mobile-ws/logactivity/"
#define kRegisterDeviceApi               @"mobile-ws/registerDevice/"
#define kLogoutApi                       @"mobile-ws/mlogout/"
#define kDashboardApi                    @"mobile-ws/dashboard"
#define kLeaderboardApi                  @"mobile-ws/leaderboard"
#define kDeviceChangedLoginApi           @"mobile-ws/mloginDeviceChanged"


#define kQSenseUDID                      @"QSenseUDID"
#define IS_OS_8_OR_LATER                 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

#define kScreenHeight                    ([UIScreen mainScreen].bounds.size.height)
#define kKeyboardHeight                  80.0f

#define kLoginTextFieldMaxLength         255


#define kAnimationDuration               0.3f

#define kUserInfoKey                     @"userInfo"
#define kLoginConnection                 1 
#define kMinDays                         7
#define kMaxDays                         0
#define kNumberOfSecondsInDay            86400

#define kLastUpdatedTimestampKeySteps    @"LastUpdatedTimestampSteps"
#define kLastUpdatedTimestampKeySleep    @"LastUpdatedTimestampSleep"
#define kLastUpdatedTimestampKeyDistance @"LastUpdatedTimestampDistance"
#define kLastUpdatedTimestampKeyFlights  @"LastUpdatedTimestampFlights"
#define kLastUpdatedTimestampKeyHeart    @"LastUpdatedTimestampHeartRate"
#define kLastUpdatedTimestampKeyWorkout  @"LastUpdatedTimestampWorkout"


#define kSensorEnabledKey                @"sensorEnabled"
#define kChartTypeKey                    @"chartType"
#define kDefaultChart                    @"Pie"
#define kLastBlockId                     @"LastBlockId"
#define kLastRecordId                    @"LastRecordId"
#define kNextBlockStartRecordId          @"LastBlockStartRecordId"
#define kRoleParticipant                 @"PARTICIPANT"
#define kFirstBlockId                    0
#define kFirstRecordId                   0
#define kHealthDataCount                 6
#define kPurgingDays                     7         //Purge data from db after 7 days

#define kHealthTimer                     1800.0f

#define kBackgroundSensorDuration        30

#define kBarChartHeight                  230.0f


#define kFieldValidationMessage          @"Both the fields are required"
#define kNoNetworkMessage                @"Network not available"
#define kServerNotFound                  @"Server not found"
#define kInvalidLoginMessage             @"Login failed. Invalid credentials."
#define kUnknownErrorMessage             @"Unknown Error"
#define kMultipleLoginTitle              @"Multiple Logins detected"
#define kMultipleLoginMessage            @"You are already logged into another device. Would you like to end the old session and start using this device."
#define kSessionExpiredMessage           @"You were logged out because your session had expired. Please login again."
#define kSensorOffMessage                @"Sensing is currently disabled in your settings. Would you like to enable it?"


#define kHelpContent                     @"<p>The <b>Dashboard</b> screen displays the total step count and a bar/pie chart representing the summary of the activities of the user for the given day. The user is allowed to navigate and see data for the past week.</p> <br /><p>The <b>Leaderboard</b> screen displays the min, max, average values of step count and other activities for a single day, 7 days or 30 days.</p><br /><p>The <b>Messages</b> screen displays the messages sent by the admin(s) to the users for advisory purposes.\n</p><br /><p>The <b>Settings</b> screen can be used to configure various user specific preferences such as disabling sensing and notifications, and selecting the chart type to be displayed on the dashboard.</p><br />"



#define kActiveTime                      @"TOTAL_ACTIVE_TIME"


#define kCategoryStatus                 @"STATUS"
#define kCategoryActivity               @"ACTIVITY"

#define kSubCategoryLocation            @"LOCATION"
#define kSubCategoryStepCount           @"STEP_COUNT"
#define kSubCategoryDistance            @"WALKING_RUNNING_DISTANCE"
#define kSubCategoryFlightsClimbed      @"FLIGHTS_CLIMBED"
#define kSubCategoryHeartRate           @"HEART_RATE"
#define kSubCategorySleep               @"SLEEP"


#define kSubCategoryAmericanFootball    @"AMERICAN_FOOTBALL"
#define kSubCategoryArchery             @"ARCHERY"
#define kSubCategoryAustralianFootball  @"AUSTRALIAN_FOOTBALL"
#define kSubCategoryBadminton           @"BADMINTON"
#define kSubCategoryBaseball            @"BASEBALL"
#define kSubCategoryBasketball          @"BASKETBALL"
#define kSubCategoryBowling             @"BOWLING"
#define kSubCategoryBoxing              @"BOXING"
#define kSubCategoryClimbing            @"CLIMBING"
#define kSubCategoryCricket             @"CRICKET"
#define kSubCategoryCrossTraining       @"CROSS_TRAINING"
#define kSubCategoryCurling             @"CURLING"
#define kSubCategoryCycling             @"ON_BICYCLE"
#define kSubCategoryDance               @"DANCE"
#define kSubCategoryDanceTraining       @"DANCE_INSPIRED_TRAINING"
#define kSubCategoryElliptical          @"ELLIPTICAL"
#define kSubCategoryEquestrianSports    @"EQUESTRIAN_SPORTS"
#define kSubCategoryFencing             @"FENCING"
#define kSubCategoryFishing             @"FISHING"
#define kSubCategoryFunctional          @"FUNCTIONAL_STRENGTH_TRAINING"
#define kSubCategoryGolf                @"GOLF"
#define kSubCategoryGymnastics          @"GYMNASTICS"
#define kSubCategoryHandball            @"HANDBALL"
#define kSubCategoryHiking              @"HIKING"
#define kSubCategoryHockey              @"HOCKEY"
#define kSubCategoryHunting             @"HUNTING"
#define kSubCategoryLacrosse            @"LACROSSE"
#define kSubCategoryMartialArts         @"MARTIAL_ARTS"
#define kSubCategoryMindAndBody         @"MIND_AND_BODY"
#define kSubCategoryCardioTraining      @"CARDIO_TRAINING"
#define kSubCategoryPaddleSports        @"PADDLE_SPORTS"
#define kSubCategoryPlay                @"PLAY"
#define kSubCategoryPreparation         @"PREPARATION_AND_RECOVERY"
#define kSubCategoryRacquetball         @"RACQUETBALL"
#define kSubCategoryRowing              @"ROWING"
#define kSubCategoryRugby               @"RUGBY"
#define kSubCategoryRun                 @"RUN"
#define kSubCategoryStill               @"STILL"
#define kSubCategorySailing             @"SAILING"
#define kSubCategorySkatingSports       @"SKATING_SPORTS"
#define kSubCategorySnowSports          @"SNOW_SPORTS"
#define kSubCategorySoccer              @"SOCCER"
#define kSubCategorySoftball            @"SOFTBALL"
#define kSubCategorySquash              @"SQUASH"
#define kSubCategoryStairClimbing       @"STAIR_CLIMBING"
#define kSubCategorySurfingSports       @"SURFING_SPORTS"
#define kSubCategorySwimming            @"SWIMMING"
#define kSubCategoryTableTennis         @"TABLE_TENNIS"
#define kSubCategoryTennis              @"TENNIS"
#define kSubCategoryTrackAndField       @"TRACK_AND_FIELD"
#define kSubCategoryTraditional         @"TRADITIONAL_STRENGTH_TRAINING"
#define kSubCategoryVolleyball          @"VOLLEYBALL"
#define kSubCategoryWalk                @"WALK"
#define kSubCategoryWaterFitness        @"WATER_FITNESS"
#define kSubCategoryWaterPolo           @"WATER_POLO"
#define kSubCategoryWaterSports         @"WATER_SPORTS"
#define kSubCategoryWrestling           @"WRESTLING"
#define kSubCategoryYoga                @"YOGA"
#define kSubCategorySensingDisabled     @"SENSING_DISABLED"


@interface AppConfig : NSObject

@end
