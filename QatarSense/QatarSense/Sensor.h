//
//  Sensor.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 19/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <CoreData/CoreData.h>

@class Reachability;

@interface Sensor : NSObject <CLLocationManagerDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) CLLocationManager * locationManager;

@property (nonatomic) BOOL isSensorRunning;

@property (nonatomic, strong) Reachability * reachability;

@property (nonatomic, strong) NSManagedObjectContext * managedObjectContext;

@property (nonatomic) NSInteger dataCount;

+ (Sensor *)sharedInstance;
-(void)startSensor;
-(void)stopSensor;
-(void)startFindingLocation;
//-(void)addSensingDisabledRecordAt:(NSDate *)date;
-(void)stopFindingLocation;

@end
