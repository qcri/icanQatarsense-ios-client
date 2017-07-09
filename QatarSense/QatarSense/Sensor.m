//
//  Sensor.m
//  QatarSense
//
//  Created by Ravi Chaudhary on 19/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <HealthKit/HealthKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Sensor.h"
#import "HelperClass.h"
#import "AppConfig.h"
#import "SensorActivity.h"
#import "AppDelegate.h"
#import "UserInfo.h"
#import "ContainerViewController.h"
#import "NSURLConnectionWithId.h"
#import "SWRevealViewController.h"
#import "DashboardViewController.h"
#import "LeaderboardViewController.h"
#import "Reachability.h"


@implementation Sensor
{
    HKHealthStore * healthStore;
    NSMutableData * responseData;
    NSInteger statusCode;
    NSTimer * timer;
    NSDate * lastLocationUpdatedTime;
}


+ (Sensor *)sharedInstance {
    static dispatch_once_t pred = 0;
    static Sensor *instance = nil;
    dispatch_once(&pred, ^{
        instance = [[Sensor alloc] init];
        AppDelegate * delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        instance->_managedObjectContext = delegate.managedObjectContext;
    });
    return instance;
}



#pragma mark -
#pragma mark Private Initialization
- (id)init {
    self = [super init];
    
    if (self) {
        
        // Add Observer
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
        
        
        // Initialize Reachability
        self.reachability = [Reachability reachabilityForInternetConnection];
    }
    
    return self;
}


- (void)reachabilityDidChange:(NSNotification *)notification {
    
    Reachability *reachability = (Reachability *)[notification object];
    
    NSLog(@"reachabilityAvailable - %d", [reachability isReachable]);
    
    //If network is reachable
    if([reachability isReachable])
    {
        //Reads all data blocks from database and sync to server
        [self syncDataBlocks];
    }
}



/*
 * @desc - Start sensing data
 */
-(void)startSensor
{
    BOOL isSensorOnFromSettings = [[[NSUserDefaults standardUserDefaults] valueForKey:kSensorEnabledKey] boolValue];
    
    if(isSensorOnFromSettings)
    {
        //Start location manager
        [self performSelector:@selector(startFindingLocation) withObject:nil afterDelay:5];
        
        //Request to access health data
        [self requestHeathData];
        
        //Start timer to read health data periodically
        timer = [NSTimer scheduledTimerWithTimeInterval:kHealthTimer
                                         target:self
                                       selector:@selector(requestHeathData)
                                       userInfo:nil
                                        repeats:YES];
        
        // Start Reachability Monitoring
        [self.reachability startNotifier];
        
        //Set flag
        self.isSensorRunning = YES;
    }
}


/*
 * @desc - Stop sensing data
 */
-(void)stopSensor
{
    if(self.isSensorRunning)
    {
        //Stop sensor
        //[NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self stopFindingLocation];
        
        if(timer)
        {
            [timer invalidate];
            timer = nil;
        }
        
        // Stop Reachability Monitoring
        [self.reachability stopNotifier];

        
        //Set flag
        self.isSensorRunning = NO;
    }
}


#pragma mark -
#pragma mark CLLocatioManager Stuff

/***********************************************
 *** Starts polling for current location ********
 ***********************************************/
-(void)startFindingLocation
{
    BOOL isSensorOnFromSettings = [[[NSUserDefaults standardUserDefaults] valueForKey:kSensorEnabledKey] boolValue];
    AppDelegate * delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(delegate.userInfo && isSensorOnFromSettings)
    {
        if(!self.locationManager)
        {
            CLLocationManager * newLocationManager = [[CLLocationManager alloc] init];
            newLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
            newLocationManager.distanceFilter = 700;
            self.locationManager = newLocationManager;
            
            self.locationManager.delegate = self;
            
            if(IS_OS_8_OR_LATER){
                NSUInteger code = [CLLocationManager authorizationStatus];
                if (code == kCLAuthorizationStatusNotDetermined && ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)] || [self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])) {
                    // choose one request according to your business.
                    if([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"]){
                        [self.locationManager requestAlwaysAuthorization];
                    } else if([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"]) {
                        [self.locationManager  requestWhenInUseAuthorization];
                    } else {
                        NSLog(@"Info.plist does not contain NSLocationAlwaysUsageDescription or NSLocationWhenInUseUsageDescription");
                    }
                }
            }
            [self.locationManager setAllowsBackgroundLocationUpdates:YES];
        }
        
        [self.locationManager startUpdatingLocation];
    }
}

-(void)stopFindingLocation
{
    if(self.locationManager)
    {
        [self.locationManager stopUpdatingLocation];
    }
}


#pragma mark - CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSString * errorType = (error.code == kCLErrorDenied) ? @"Access Denied" : @"Unknown Error";
    
    NSLog(@"Error getting Location - %@", errorType);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    if(lastLocationUpdatedTime)
    {
        double diff = fabs([lastLocationUpdatedTime timeIntervalSinceNow]);
        if(diff < 30)
        {
            return;
        }
    }
    
    lastLocationUpdatedTime = [NSDate date];
    
    NSLog(@"didUpdateToLocation: %@, %ld", [locations lastObject], [locations count]);
    CLLocation *currentLocation = [locations lastObject];
    
    if (currentLocation != nil)
    {
        NSString * latitude = [NSString stringWithFormat:@"%f", currentLocation.coordinate.latitude];
        NSString * longitude = [NSString stringWithFormat:@"%f", currentLocation.coordinate.longitude];
        
        NSLog(@"%@, %@", latitude, longitude);
        
        
        //Get last updated timestamp
        double lastUpdatedTimestamp =  [self maxLastUpdatedTimestamp];
        
        if(lastUpdatedTimestamp < 1)
        {
            lastUpdatedTimestamp = [[NSDate date] timeIntervalSince1970];
        }
        
        NSDate * startDate = [NSDate dateWithTimeIntervalSince1970:lastUpdatedTimestamp];

        //Create model containg location data
        SensorActivity * sensorActivityData = [self activityDataModelFor:kCategoryStatus subCategory:kSubCategoryLocation startDate:startDate value1:latitude value2:longitude value3:nil];
        
        
        //Save location record in core data
        [self saveRecords:@[sensorActivityData]];
    }
}


/*
 * @desc - Returns max lastUpdated timestamp value for health data
 */
-(double)maxLastUpdatedTimestamp
{
    double maxValue = 0;
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    double lastUpdatedTimestamp =  [[userDefaults objectForKey:kLastUpdatedTimestampKeySteps] doubleValue];
    if(maxValue < lastUpdatedTimestamp)
        maxValue = lastUpdatedTimestamp;
    
    lastUpdatedTimestamp =  [[userDefaults objectForKey:kLastUpdatedTimestampKeyWorkout] doubleValue];
    if(maxValue < lastUpdatedTimestamp)
        maxValue = lastUpdatedTimestamp;
    
    lastUpdatedTimestamp =  [[userDefaults objectForKey:kLastUpdatedTimestampKeySleep] doubleValue];
    if(maxValue < lastUpdatedTimestamp)
        maxValue = lastUpdatedTimestamp;
    
    lastUpdatedTimestamp =  [[userDefaults objectForKey:kLastUpdatedTimestampKeyHeart] doubleValue];
    if(maxValue < lastUpdatedTimestamp)
        maxValue = lastUpdatedTimestamp;
    
    lastUpdatedTimestamp =  [[userDefaults objectForKey:kLastUpdatedTimestampKeyFlights] doubleValue];
    if(maxValue < lastUpdatedTimestamp)
        maxValue = lastUpdatedTimestamp;
    
    lastUpdatedTimestamp =  [[userDefaults objectForKey:kLastUpdatedTimestampKeyDistance] doubleValue];
    if(maxValue < lastUpdatedTimestamp)
        maxValue = lastUpdatedTimestamp;
    
    
    return maxValue;
}


//-(void)addSensingDisabledRecordAt:(NSDate *)date
//{
//    //Store data in db
//    SensorActivity * sensorActivityData = [self activityDataModelFor:kCategoryActivity subCategory:kSubCategorySensingDisabled startDate:date value1:nil value2:nil value3:nil];
//    
//    [self storeActivityDataInDB:@[sensorActivityData]];
//}


#pragma mark - Health kit methods

-(void)requestHeathData
{
    if(NSClassFromString(@"HKHealthStore") && [HKHealthStore isHealthDataAvailable])
    {   
        healthStore = [[HKHealthStore alloc] init];
        
//        // Share body mass, height and body mass index
//        NSSet *shareObjectTypes = [NSSet setWithObjects:
//                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],
//                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],
//                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex],
//                                   nil];
        
        // Read date of birth, biological sex and step count
        NSSet *readObjectTypes  = [NSSet setWithObjects:
                                   [HKObjectType workoutType],
                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning],
                                   [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],
                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed],
                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate],
                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
                                   nil];
        
        // Request access
        [healthStore requestAuthorizationToShareTypes:nil
                                            readTypes:readObjectTypes
                                           completion:^(BOOL success, NSError *error) {
                                               
                                               if(success == YES)
                                               {
                                                   //Read sleep data
                                                   [self readSleepData];
                                                   
                                                   //Read Step count
                                                   [self readHealthDataForQuantity:HKQuantityTypeIdentifierStepCount];

                                                   //Read Heart Rate
                                                   [self readHealthDataForQuantity:HKQuantityTypeIdentifierHeartRate];
                                                   
                                                   //Read Flights Climbed
                                                   [self readHealthDataForQuantity:HKQuantityTypeIdentifierFlightsClimbed];
                                                   
                                                   //Read Walking running Distance
                                                   [self readHealthDataForQuantity:HKQuantityTypeIdentifierDistanceWalkingRunning];
                                                   
                                                   //Read all workouts
                                                   [self readWorkouts];
                                               }
                                               else
                                               {
                                                   // Determine if it was an error or if the
                                                   // user just canceld the authorization request
                                               }
                                               
                                           }];
    }
}

/*
 * @desc - Reads sleep data from health kit
 */
-(void)readSleepData
{
    //Get last updated timestamp
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    double lastUpdatedTimestamp =  [[userDefaults objectForKey:kLastUpdatedTimestampKeySleep] doubleValue];
    if(lastUpdatedTimestamp < 1)
    {
        lastUpdatedTimestamp = [[NSDate date]timeIntervalSince1970] - 8 * kNumberOfSecondsInDay;
    }
        
    
    // Set your start and end date for your query of interest
    NSDate *startDate, *endDate;
    endDate = [NSDate date];
    startDate = [NSDate dateWithTimeIntervalSince1970:lastUpdatedTimestamp];
    
    // Use the sample type for step count
    HKSampleType *sampleType = [HKSampleType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    
    // Create a predicate to set start/end date bounds of the query
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    
    // Create a sort descriptor for sorting by start date
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                                 predicate:predicate
                                                                     limit:HKObjectQueryNoLimit
                                                           sortDescriptors:@[sortDescriptor]
                                                            resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                                
                                                                //Increase dataCount
                                                                self.dataCount = self.dataCount + 1;
                                                                
                                                                if(!error && results && results.count > 0)
                                                                {
                                                                    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:YES];
                                                                    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                                                                    
                                                                    results = [results sortedArrayUsingDescriptors:sortDescriptors];
                                                                    
                                                                    //Traverse through array of results and record each data item
                                                                    NSMutableArray * itemsArray = [[NSMutableArray alloc]init];
                                                                    
                                                                    for(HKCategorySample *sample in results)
                                                                    {
                                                                        if(sample.value == 1)
                                                                        {
                                                                            NSDate * startDate = sample.startDate;
                                                                            NSDate * endDate = sample.endDate;
                                                                            double seconds = [endDate timeIntervalSinceDate:startDate];
                                                                            double minutes = seconds / 60;
                                                                            
                                                                            NSString * valueString = [NSString stringWithFormat:@"%ld", (NSInteger)minutes];
                                                                            
                                                                            
                                                                            //Store data in db
                                                                            SensorActivity * sensorActivityData = [self activityDataModelFor:kCategoryStatus subCategory:kSubCategorySleep startDate:startDate value1:valueString value2:nil value3:nil];
                                                                            
                                                                            [itemsArray addObject:sensorActivityData];
                                                                        }
                                                                        
                                                                    }
                                                                    
                                                                    HKCategorySample *sample = [results lastObject];
                                                                    
                                                                    //Update last updated timestamp
                                                                    [userDefaults setObject:[NSNumber numberWithDouble:[sample.endDate timeIntervalSince1970]] forKey:kLastUpdatedTimestampKeySleep];
                                                                    
                                                                    NSLog(@"Sleep Items = %ld", itemsArray.count);
                                                                    
                                                                    //dispatch_async(dispatch_get_main_queue(), ^{
                                                                        //Your main thread code goes in here
                                                                        [self storeActivityDataInDB:itemsArray];
                                                                    //});
                                                                    
                                                                }
                                                                else
                                                                {
                                                                    //dispatch_async(dispatch_get_main_queue(), ^{
                                                                        //Your main thread code goes in here
                                                                        [self storeActivityDataInDB:@[]];
                                                                    //});
                                                                    
                                                                }
                                                                
                                                            }];
    
    // Execute the query
    [healthStore executeQuery:sampleQuery];
}

-(NSString *)timestampKeyNameForCategory : (NSString *)category
{
    NSString * key;
    
    if([category isEqualToString:HKQuantityTypeIdentifierStepCount])
    {
        key = kLastUpdatedTimestampKeySteps;
    }
    else if([category isEqualToString:HKQuantityTypeIdentifierHeartRate])
    {
        key = kLastUpdatedTimestampKeyHeart;
    }
    else if([category isEqualToString:HKQuantityTypeIdentifierFlightsClimbed])
    {
        key = kLastUpdatedTimestampKeyFlights;
    }
    else if([category isEqualToString:HKQuantityTypeIdentifierDistanceWalkingRunning])
    {
        key = kLastUpdatedTimestampKeyDistance;
    }
    
    return key;
}

/*
 * @desc - Reads health data from health kit for quantity passed as parameter
 */
-(void)readHealthDataForQuantity : (NSString *)quantityTypeIdentifier
{
    NSString * timestampKey = [self timestampKeyNameForCategory:quantityTypeIdentifier];
    if(timestampKey == nil)
    {
        return;
    }
    
    //Get last updated timestamp
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    double lastUpdatedTimestamp =  [[userDefaults objectForKey:timestampKey] doubleValue];
    
    if(lastUpdatedTimestamp < 1)
    {
        lastUpdatedTimestamp = [[NSDate date]timeIntervalSince1970] - 8 * kNumberOfSecondsInDay;
    }

    
    // Set your start and end date for your query of interest
    NSDate *startDate, *endDate;
    endDate = [NSDate date];
    startDate = [NSDate dateWithTimeIntervalSince1970:lastUpdatedTimestamp];
    
    
    // Use the sample type for step count
    HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:quantityTypeIdentifier];
    
    // Create a predicate to set start/end date bounds of the query
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    
    // Create a sort descriptor for sorting by start date
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                                 predicate:predicate
                                                                     limit:HKObjectQueryNoLimit
                                                           sortDescriptors:@[sortDescriptor]
                                                            resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                                
                                                                //Increase dataCount
                                                                self.dataCount = self.dataCount + 1;
                                                                
                                                                if(!error && results && results.count > 0)
                                                                {
                                                                    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:YES];
                                                                    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                                                                    
                                                                    results = [results sortedArrayUsingDescriptors:sortDescriptors];
                                                                    
                                                                    HKUnit * unit;
                                                                    NSString * subcategory;
                                                                    
                                                                    //Find unit and subcategory name
                                                                    if([quantityTypeIdentifier isEqualToString:HKQuantityTypeIdentifierStepCount])
                                                                    {
                                                                        unit = [HKUnit countUnit];
                                                                        subcategory = kSubCategoryStepCount;
                                                                    }
                                                                    else if([quantityTypeIdentifier isEqualToString:HKQuantityTypeIdentifierHeartRate])
                                                                    {
                                                                        unit = [HKUnit unitFromString:@"count/min"];
                                                                        subcategory = kSubCategoryHeartRate;
                                                                    }
                                                                    else if([quantityTypeIdentifier isEqualToString:HKQuantityTypeIdentifierFlightsClimbed])
                                                                    {
                                                                        unit = [HKUnit countUnit];
                                                                        subcategory = kSubCategoryFlightsClimbed;
                                                                    }
                                                                    else if([quantityTypeIdentifier isEqualToString:HKQuantityTypeIdentifierDistanceWalkingRunning])
                                                                    {
                                                                        subcategory = kSubCategoryDistance;
                                                                        unit = [HKUnit meterUnitWithMetricPrefix:HKMetricPrefixKilo];
                                                                    }
                                                                    else
                                                                    {
                                                                        return;
                                                                    }
                                                                    
                                                                    //Traverse through array of results and record each data item
                                                                    NSMutableArray * itemsArray = [[NSMutableArray alloc]init];
                                                                    
                                                                    for(HKQuantitySample *sample in results)
                                                                    {
                                                                        NSDate * startDate = sample.startDate;
                                                                        
                                                                        double value = [sample.quantity doubleValueForUnit:unit];
                                                                        
                                                                        NSString * valueString;
                                                                        if([quantityTypeIdentifier isEqualToString:HKQuantityTypeIdentifierDistanceWalkingRunning])
                                                                        {
                                                                            valueString = [NSString stringWithFormat:@"%.2f", value];
                                                                        }
                                                                        else
                                                                        {
                                                                            valueString = [NSString stringWithFormat:@"%.0f", value];
                                                                        }
                                                                        
                                                                        
                                                                        //Store data in db
                                                                        SensorActivity * sensorActivityData = [self activityDataModelFor:kCategoryStatus subCategory:subcategory startDate:startDate value1:valueString value2:nil value3:nil];
                                                                        
                                                                        [itemsArray addObject:sensorActivityData];
                                                                        
                                                                    }
                                                                    
                                                                    HKQuantitySample *sample = [results lastObject];
                                                                    
                                                                    //Update last updated timestamp
                                                                    [userDefaults setObject:[NSNumber numberWithDouble:[[sample.startDate dateByAddingTimeInterval:1] timeIntervalSince1970]] forKey:timestampKey];
                                                                    
                                                                    NSLog(@"Items = %ld", itemsArray.count);
                                                                    
                                                                    //dispatch_async(dispatch_get_main_queue(), ^{
                                                                        //Your main thread code goes in here
                                                                        [self storeActivityDataInDB:itemsArray];
                                                                    //});
                                                                    
                                                                    
                                                                    
                                                                }
                                                                else
                                                                {
                                                                    //dispatch_async(dispatch_get_main_queue(), ^{
                                                                        //Your main thread code goes in here
                                                                        [self storeActivityDataInDB:@[]];
                                                                    //});
                                                                }
                                                                
                                                            }];
    
    // Execute the query
    [healthStore executeQuery:sampleQuery];
}




/*
 * @desc - Reads workouts data from hrealth kit
 */
-(void)readWorkouts
{
    //Get last updated timestamp
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    double lastUpdatedTimestamp =  [[userDefaults objectForKey:kLastUpdatedTimestampKeyWorkout] doubleValue];
    
    if(lastUpdatedTimestamp < 1)
    {
        lastUpdatedTimestamp = [[NSDate date]timeIntervalSince1970] - 8 * kNumberOfSecondsInDay;
    }
    
    // Set your start and end date for your query of interest
    NSDate *startDate, *endDate;
    endDate = [NSDate date];
    startDate = [NSDate dateWithTimeIntervalSince1970:lastUpdatedTimestamp];
    
    HKObjectType * sampleType = [HKObjectType workoutType];
    
    NSPredicate * predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    
    // Create a sort descriptor for sorting by start date
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:(HKSampleType *)sampleType
                                                                 predicate:predicate
                                                                     limit:HKObjectQueryNoLimit
                                                           sortDescriptors:@[sortDescriptor]
                                                            resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                                
                                                                //Increase dataCount
                                                                self.dataCount = self.dataCount + 1;
                                                                
                                                            if(!error && results && results.count > 0)
                                                                {
                                                                    NSMutableArray * activityDataArray = [[NSMutableArray alloc]init];
                                                                    
                                                                    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:YES];
                                                                    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                                                                    
                                                                    results = [results sortedArrayUsingDescriptors:sortDescriptors];
                                                                    
                                                                    HKWorkout * prevWorkout = nil;
                                                                    for(HKWorkout * workout in results)
                                                                    {
//                                                                        NSLog(@"{\nStart = %@ \nEnd = %@\n Duration = %.0f\nActivity Type =  %@\n}", workout.startDate, workout.endDate, workout.duration, [HelperClass getActivityTypeString:(int)workout.workoutActivityType]);
                                                                        NSString * subcategoryName = [HelperClass getActivityTypeString:(int)workout.workoutActivityType];
                                                                      
                                                                        
                                                                        if(prevWorkout)
                                                                        {
                                                                            if([prevWorkout.endDate compare:workout.startDate] == NSOrderedAscending)
                                                                            {
                                                                                //Store data in db
                                                                                SensorActivity * sensorActivityData = [self activityDataModelFor:kCategoryActivity subCategory:kSubCategoryStill startDate:prevWorkout.endDate value1:nil value2:nil value3:nil];
                                                                                
                                                                                [activityDataArray addObject:sensorActivityData];
                                                                            }
                                                                        }
                                                                        
                                                                        //Update last workout
                                                                        prevWorkout = workout;
                                                                        
                                                                        //Store data in db
                                                                        SensorActivity * sensorActivityData = [self activityDataModelFor:kCategoryActivity subCategory:subcategoryName startDate:workout.startDate value1:nil value2:nil value3:nil];
                                                                        
                                                                        [activityDataArray addObject:sensorActivityData];
                                                                        
                                                                    }
                                                                    
                                                                    HKWorkout * workout = [results lastObject];
                                                                    
                                                                    //Update last updated timestamp
                                                                    [userDefaults setObject:[NSNumber numberWithDouble:[workout.endDate timeIntervalSince1970]] forKey:kLastUpdatedTimestampKeyWorkout];

                                                                    //Store data in db
                                                                    SensorActivity * sensorActivityData = [self activityDataModelFor:kCategoryActivity subCategory:kSubCategoryStill startDate:workout.endDate value1:nil value2:nil value3:nil];
                                                                    
                                                                    [activityDataArray addObject:sensorActivityData];

                                                                    //dispatch_async(dispatch_get_main_queue(), ^{
                                                                        //Your main thread code goes in here
                                                                        [self storeActivityDataInDB:activityDataArray];
                                                                    //});
                                                                    
                                                                    NSLog(@"Workouts - %ld", [activityDataArray count]);
                                                                }
                                                                else
                                                                {
                                                                    //dispatch_async(dispatch_get_main_queue(), ^{
                                                                        //Your main thread code goes in here
                                                                        [self storeActivityDataInDB:@[]];
                                                                    //});
                                                                }
                                                            }];
    
    // Execute the query
    [healthStore executeQuery:sampleQuery];
}



-(SensorActivity *)activityDataModelFor:(NSString *)category subCategory:(NSString *)subCategory startDate:(NSDate *)startDate value1 : (NSString *)value1 value2 : (NSString *)value2 value3 : (NSString *)value3
{
    //Create sensorActivity Model object and populate it
    SensorActivity * sensorActivity = [[SensorActivity alloc]init];
    sensorActivity.category = category;
    sensorActivity.subCategory = subCategory;
    sensorActivity.field1 = value1 ? value1 : @"";
    sensorActivity.field2 = value2 ? value2 : @"";
    sensorActivity.field3 = value3 ? value3 : @"";
    sensorActivity.timestamp = [startDate timeIntervalSince1970];
    sensorActivity.timestampString = [NSString stringWithFormat:@"%f", sensorActivity.timestamp];
    
    //Create date formatter
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss zzz"];
    sensorActivity.date1 = [dateFormatter stringFromDate:startDate];
    [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
    sensorActivity.date2 = [dateFormatter stringFromDate:startDate];
    
    sensorActivity.dateCreated = [dateFormatter stringFromDate:[NSDate date]];
    sensorActivity.dateModified = [dateFormatter stringFromDate:[NSDate date]];
    
    return sensorActivity;
}


-(void)storeActivityDataInDB : (NSArray *)dataArray
{
    if(dataArray && [dataArray count] > 0)
    {
        //Save record in core date
        [self saveRecords:dataArray];
    }
    
    if (self.dataCount >= kHealthDataCount)
    {
        self.dataCount = 0;
        
        //Save data block record for all activity records saved
        [self saveDataBlockRecord];
        
        //Reads all data blocks from database and sync to server
        [self syncDataBlocks];
    }
}


/*
 * @desc - Saves the reocords in UserActivities entity
 */
-(void)saveRecords : (NSArray *)records
{
    //Create a temprary context and set managedObjectCOntext as its parent
    NSManagedObjectContext * temporaryContext = [[NSManagedObjectContext alloc]initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = _managedObjectContext;
    
    [temporaryContext performBlockAndWait:^{
    
        AppDelegate * delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
        NSUInteger startRecordId = [[userDefaults objectForKey:kLastRecordId] longValue] + 1;
        NSUInteger endRecordId = startRecordId + records.count - 1;
        
        //Update lastRecordId in user defaults
        NSInteger oldValueOfLastRecordId = [[userDefaults objectForKey:kLastRecordId] longValue];
        [userDefaults setObject:[NSNumber numberWithInteger:endRecordId] forKey:kLastRecordId];
        [userDefaults synchronize];
        
        // Create entity description object for entiy "UserActivities"
        NSEntityDescription * entityDescription = [NSEntityDescription entityForName:@"UserActivities" inManagedObjectContext:temporaryContext];
        
        
        //Traverse through array and save all records in entity
        NSUInteger i = startRecordId;
        for (SensorActivity * activity in records) {
            
            NSManagedObject *newRecord = [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:temporaryContext];
            
            //Populate record
            [newRecord setValue:[NSNumber numberWithInteger:i] forKey:@"id"];
            [newRecord setValue:[NSNumber numberWithInteger:delegate.userInfo.userId] forKey:@"userId"];
            [newRecord setValue:[NSNumber numberWithInteger:delegate.userInfo.sessionId] forKey:@"sessionId"];
            [newRecord setValue:[NSNumber numberWithDouble:activity.timestamp] forKey:@"timestamp"];
            [newRecord setValue:[NSString stringWithFormat:@"%@", activity.field1] forKey:@"field1"];
            [newRecord setValue:[NSString stringWithFormat:@"%@", activity.field2] forKey:@"field2"];
            [newRecord setValue:[NSString stringWithFormat:@"%@", activity.field3] forKey:@"field3"];
            [newRecord setValue:[NSString stringWithFormat:@"%@", activity.category] forKey:@"category"];
            [newRecord setValue:[NSString stringWithFormat:@"%@", activity.subCategory] forKey:@"subCategory"];
            [newRecord setValue:[NSString stringWithFormat:@"%@", activity.timestampString] forKey:@"timestampString"];
            [newRecord setValue:[NSString stringWithFormat:@"%@", activity.date1] forKey:@"date1"];
            [newRecord setValue:[NSString stringWithFormat:@"%@", activity.date2] forKey:@"date2"];
            [newRecord setValue:[NSString stringWithFormat:@"%@", activity.dateCreated] forKey:@"dateCreated"];
            [newRecord setValue:[NSString stringWithFormat:@"%@", activity.dateModified] forKey:@"dateModified"];
            
            //Increment i to get next record Id
            i++;
        }
        
        NSError * error;
        if(![temporaryContext save:&error])
        {
            NSLog(@"Save Error : %@", [error localizedDescription]);
            
            [userDefaults setObject:[NSNumber numberWithInteger:oldValueOfLastRecordId] forKey:kLastRecordId];
            [userDefaults synchronize];
        }
        
        [_managedObjectContext performBlockAndWait:^{
            NSError * error;
            if(![_managedObjectContext save:&error])
            {
                NSLog(@"Save Error : %@", [error localizedDescription]);
            }
        }];
    }];
    
    
}

/*
 * @desc - Saves data block record in FataBlock entity
 */
-(void)saveDataBlockRecord
{
    //Retrieve last blockId and lastRecordId from user defaults and calculate next block id, startRecordId and endRecordId
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSUInteger blockId = [[userDefaults objectForKey:kLastBlockId] longValue] + 1;
    NSUInteger startRecordId = [[userDefaults objectForKey:kNextBlockStartRecordId] longValue];
    NSUInteger endRecordId = [[userDefaults objectForKey:kLastRecordId] longValue];
    
    
    //If start is greater than end, just do not save data block record
    if(startRecordId > endRecordId)
    {
        return;
    }
    
    //Update lastBlockId and NextBlockStartRecordId in user defaults
    NSInteger oldValueOfBlockId = [[userDefaults objectForKey:kLastBlockId] longValue];
    NSInteger oldValueOfNextBlockStartRecordId = [[userDefaults objectForKey:kNextBlockStartRecordId] longValue];
    
    [userDefaults setObject:[NSNumber numberWithInteger:blockId] forKey:kLastBlockId];
    [userDefaults setObject:[NSNumber numberWithInteger:endRecordId + 1] forKey:kNextBlockStartRecordId];
    [userDefaults synchronize];
    
    //Create a temprary context and set managedObjectCOntext as its parent
    NSManagedObjectContext * temporaryContext = [[NSManagedObjectContext alloc]initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = _managedObjectContext;
    
    [temporaryContext performBlockAndWait:^{
        
        AppDelegate * delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        // Create entity description object for entiy "DataBlock"
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"DataBlock" inManagedObjectContext:temporaryContext];

        //Create managed object
        NSManagedObject *newRecord = [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:temporaryContext];


        //Populate record
        [newRecord setValue:[NSNumber numberWithInteger:blockId] forKey:@"id"];
        [newRecord setValue:[NSNumber numberWithInteger:startRecordId] forKey:@"startRecordId"];
        [newRecord setValue:[NSNumber numberWithInteger:endRecordId] forKey:@"endRecordId"];
        [newRecord setValue:[NSNumber numberWithInteger:delegate.userInfo.userId] forKey:@"userId"];
        [newRecord setValue:[NSNumber numberWithInteger:delegate.userInfo.sessionId] forKey:@"sessionId"];
        
        
        //Create date formatter
        NSDateFormatter * dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
        NSString * createdTime = [dateFormatter stringFromDate:[NSDate date]];
        
        //Set createdTime
        [newRecord setValue:[NSString stringWithFormat:@"%@", createdTime] forKey:@"createdTime"];
        
        NSError * error;
        if (![temporaryContext save:&error]) {
            NSLog(@"Save Error : %@", [error localizedDescription]);
            
            [userDefaults setObject:[NSNumber numberWithInteger:oldValueOfBlockId] forKey:kLastBlockId];
            [userDefaults setObject:[NSNumber numberWithInteger:oldValueOfNextBlockStartRecordId] forKey:kNextBlockStartRecordId];
            [userDefaults synchronize];
        }
        
        [_managedObjectContext performBlockAndWait:^{
            NSError * error;
            if(![_managedObjectContext save:&error])
            {
                NSLog(@"Save Error : %@", [error localizedDescription]);
            }
        }];
        
    }];

}


/*
 * @desc - Reads all data blocks from database and sync to server
 */
-(void)syncDataBlocks
{
    [_managedObjectContext performBlockAndWait:^{
    
        AppDelegate * delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        // Create fetchRequest object
        NSFetchRequest * dataBlockRequest = [[NSFetchRequest alloc]init];
        
        // Create entity description object for entiy "DataBlock"
        NSEntityDescription *dataBlockEntityDescription = [NSEntityDescription entityForName:@"DataBlock" inManagedObjectContext:_managedObjectContext];
        
        [dataBlockRequest setEntity:dataBlockEntityDescription];
        
        NSError * error;
        NSArray * dataBlockResults = [_managedObjectContext executeFetchRequest:dataBlockRequest error:&error];
            
        if(dataBlockResults && dataBlockResults.count > 0)
        {
            for (NSManagedObject * dataBlockRecord in dataBlockResults) {
                
                NSUInteger blockId = [[dataBlockRecord valueForKey:@"id"] integerValue];
                
                //Create date formatter
                NSDateFormatter * dateFormatter = [[NSDateFormatter alloc]init];
                [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
                NSString * createdTimeString = [dataBlockRecord valueForKey:@"createdTime"];
                NSDate * createdTime = [dateFormatter dateFromString:createdTimeString];
                
                NSDate * purgeTime = [[NSDate date] dateByAddingTimeInterval:-(kPurgingDays * kNumberOfSecondsInDay)];
                
                //If Data block's created time is before purge time
                if([createdTime compare:purgeTime] == NSOrderedAscending)
                {
                    //Remove record of data block with blockId  and associated activity records from database
                    [self removeDataForDataBlock : blockId];
                }
                else
                {
                    //If userId is equal to logged in user id and network is available, then sync the data block to server
                    NSUInteger userId = [[dataBlockRecord valueForKey:@"userId"] integerValue];
                    if(userId == delegate.userInfo.userId && [HelperClass isNetworkAvailable])
                    {
                        /*
                         * Sync the data block to server
                         */
                        
                        NSUInteger startRecordId = [[dataBlockRecord valueForKey:@"startRecordId"] integerValue];
                        NSUInteger endRecordId = [[dataBlockRecord valueForKey:@"endRecordId"] integerValue];
                        
                        // Create fetchRequest object
                        NSFetchRequest * activitiesDataRequest = [[NSFetchRequest alloc]init];
                        
                        //Create predicate
                        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"id>=%ld AND id<=%ld", startRecordId, endRecordId];
                        
                        [activitiesDataRequest setPredicate:predicate];
                        
                        // Create entity description object for entiy "DataBlock"
                        NSEntityDescription *activitiesEntityDescription = [NSEntityDescription entityForName:@"UserActivities" inManagedObjectContext:_managedObjectContext];
                        
                        [activitiesDataRequest setEntity:activitiesEntityDescription];
                        
                        NSError * error;
                        
                        NSArray * activitiesResults = [_managedObjectContext executeFetchRequest:activitiesDataRequest error:&error];
                        if(activitiesResults && activitiesResults.count > 0)
                        {
                            //Form payload
                            NSDictionary * payload = [self formPayloadForData : dataBlockRecord and : activitiesResults];
                            
                            //Sync data to server
                            [self syncData:payload blockId:blockId];
                        }
                        else
                        {
                            NSLog(@"%@", error ? error.description : @"No data found in UserActivities entity");
                        }
                    }
                }
            }
        }
        else
        {
            NSLog(@"%@", error ? error.description : @"No data found in DataBlocks entity");
            
        }
    }];
}

/*
 * @desc - Forms payload data
 */
-(NSDictionary *)formPayloadForData:(NSManagedObject *)dataBlock and:(NSArray *)activities
{
    AppDelegate * delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSUInteger blockId = [[dataBlock valueForKey:@"id"] integerValue];
    NSUInteger startRecordId = [[dataBlock valueForKey:@"startRecordId"] integerValue];
    NSUInteger endRecordId = [[dataBlock valueForKey:@"endRecordId"] integerValue];

    NSMutableArray * array = [[NSMutableArray alloc]init];
    for (NSManagedObject * activityRecord in activities) {
        
        NSMutableDictionary * dictionary = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSString stringWithFormat:@"%@", [activityRecord valueForKey:@"date2"]], @"timestamp", [NSString stringWithFormat:@"%@", [activityRecord valueForKey:@"subCategory"]], @"subCategoryName", [NSString stringWithFormat:@"%@", [activityRecord valueForKey:@"field1"]], @"field1", [NSString stringWithFormat:@"%@", [activityRecord valueForKey:@"field2"]], @"field2", [NSString stringWithFormat:@"%@", [activityRecord valueForKey:@"field3"]], @"field3", [NSString stringWithFormat:@"%ld", [[activityRecord valueForKey:@"sessionId"] integerValue]], @"sessionId", [NSString stringWithFormat:@"%ld", [[activityRecord valueForKey:@"id"] integerValue]], @"sessionRecordId",  nil];
        
        [array addObject:dictionary];
    }
    
    NSMutableDictionary * payload = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSString stringWithFormat:@"%ld", delegate.userInfo.sessionId], @"sessionId", [NSString stringWithFormat:@"%ld", blockId], @"blockId", [NSString stringWithFormat:@"%ld", startRecordId], @"sessionRecordStartId", [NSString stringWithFormat:@"%ld", endRecordId], @"sessionRecordEndId", array, @"userObservations", nil];
    

    
    return payload;
}


/*
 * @desc - Sends request to download dashboard data
 */
-(void)syncData : (NSDictionary *)data blockId : (NSUInteger)blockId
{
    AppDelegate * delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UserInfo * userInfo = delegate.userInfo;
    
    if(userInfo)
    {
        //Create url
        NSString * urlString = [NSString stringWithFormat:@"%@%@", kServerBaseUrl, kLogActivitiesApi];
        NSURL * url = [NSURL URLWithString:urlString];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        
        //Set http method as POST
        [request setHTTPMethod:@"POST"];
        
        //Set request headers
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%ld", userInfo.userId] forHTTPHeaderField:@"userId"];
        [request setValue:userInfo.authToken forHTTPHeaderField:@"authToken"];
        [request setValue:[HelperClass gmtString] forHTTPHeaderField:@"timezoneId"];
        [request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
        
        //Create post data
        NSError *error;

        NSData *postData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
        [request setHTTPBody:postData];
        
        
        //Create connection and start to download data
        NSURLConnectionWithId * connection = [[NSURLConnectionWithId alloc] initWithRequest:request delegate:self startImmediately:NO connectionId:blockId];
        
        [connection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                              forMode:NSDefaultRunLoopMode];
        [connection start];
    }
}

#pragma mark - NSURLConnection Delegate Methods

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    
    //Create responseData to store the response
    NSMutableData * mutableData = [[NSMutableData alloc]init];
    responseData = mutableData;
    
    //Get status code
    statusCode = [(NSHTTPURLResponse *)response statusCode];
    NSLog(@"%ld", (long)statusCode);
    if (statusCode == 401)     //session expired error
    {
        [HelperClass showSessionExpiredMessage];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //Append all of the response to the responseData object
    [responseData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if(statusCode == 200)
    {
        //Convert JSON response into a dictionary object
        NSError * error;
        NSDictionary * responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
        
        NSLog(@"Response : %@", responseDict);
        
        if([[responseDict objectForKey:@"success"] boolValue])
        {
            NSLog(@"Successful");
            
            //get blockId
            NSUInteger blockId = ((NSURLConnectionWithId *)connection).connectionId;
            
            //Remove record of data block with blockId  and associated activity records from database
            [self removeDataForDataBlock : blockId];
            
            //Start updating dashboard or leaderboard whichever is currently open
            [self updateDashboardOrLeaderboard];
        }
        else
        {
            NSLog(@"Failed");
        }
    }
    
    
}


-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Error");
}



/*
 * @desc - Remove the record with blockId from entity "DataBlock" and associated records from entity "UserActivity"
 */
-(void)removeDataForDataBlock:(NSUInteger)blockId
{
    [_managedObjectContext performBlockAndWait:^{
        
        // Create fetchRequest object
        NSFetchRequest * request = [[NSFetchRequest alloc]init];
        
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"id==%ld", blockId];
        [request setPredicate:predicate];
        
        // Create entity description object for entiy "DataBlock"
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"DataBlock" inManagedObjectContext:_managedObjectContext];
        
        [request setEntity:entityDescription];
        
        NSError * error;
        NSArray * dataBlockResults = [_managedObjectContext executeFetchRequest:request error:&error];
        if(dataBlockResults && dataBlockResults.count > 0)
        {
            NSManagedObject * dataBlockRecord = [dataBlockResults lastObject];
            NSUInteger startRecordId = [[dataBlockRecord valueForKey:@"startRecordId"] integerValue];
            NSUInteger endRecordId = [[dataBlockRecord valueForKey:@"endRecordId"] integerValue];
            
            // Create fetchRequest object
            NSFetchRequest * activityRequest = [[NSFetchRequest alloc]init];
            
            NSPredicate * activityPredicate = [NSPredicate predicateWithFormat:@"id>=%ld AND id<=%ld", startRecordId, endRecordId];
            [activityRequest setPredicate:activityPredicate];
            
            // Create entity description object for entiy "UserActivities"
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"UserActivities" inManagedObjectContext:_managedObjectContext];
            
            [activityRequest setEntity:entityDescription];
            
            NSError * fetchError;
            NSArray * activitiesResults = [_managedObjectContext executeFetchRequest:activityRequest error:&fetchError];
            
            if(!fetchError && activitiesResults && activitiesResults.count > 0)
            {
                for (NSManagedObject * record in activitiesResults) {
                    //Delete record from entity "UserActivity"
                    [_managedObjectContext deleteObject:record];
                }
            }
            
            //Delete record from entity "DataBlock "
            [_managedObjectContext deleteObject:dataBlockRecord];
            
            NSError * error;
            if(![_managedObjectContext save:&error])
            {
                NSLog(@"Save Error : %@", [error localizedDescription]);
            }
            
        }
    }];
}

/*
 * @desc - Update data on dashboard or leaderboard whichever is currently open
 */
-(void)updateDashboardOrLeaderboard
{
    //Show user's full name on rear view's navigation bar and start downloading dashboad data
    AppDelegate * delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    ContainerViewController * containerViewController = (ContainerViewController *)delegate.window.rootViewController;
    SWRevealViewController * revealController = (SWRevealViewController *)containerViewController.viewControllers[0];
    
    UINavigationController * frontViewController = (UINavigationController *)revealController.frontViewController;
    
    if(frontViewController.viewControllers.count > 0)
    {
        UIViewController * viewController = frontViewController.viewControllers[0];
        
        if([viewController respondsToSelector:@selector(downloadData)])
        {
            [viewController performSelector:@selector(downloadData)];
        }
    }
}


@end
