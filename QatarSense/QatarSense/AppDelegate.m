//
//  AppDelegate.m
//  QatarSense
//
//  Created by Ravi Chaudhary on 03/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import "AppDelegate.h"
#import <Foundation/Foundation.h>
#import "Sensor.h"
#import "AppConfig.h"
#import "UserInfo.h"
#import "notify.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.


    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];

    NSNumber * number = [userDefaults valueForKey:kLastBlockId];
    if(number == nil)
    {
        [userDefaults setValue:[NSNumber numberWithInteger:kFirstBlockId] forKey:kLastBlockId];
        [userDefaults setValue:[NSNumber numberWithInteger:1] forKey:kNextBlockStartRecordId];
        [userDefaults setValue:[NSNumber numberWithInteger:kFirstRecordId] forKey:kLastRecordId];
        [userDefaults synchronize];
    }


//Pending part -
//    //If user is logged in
//    if([userDefaults objectForKey:kUserInfoKey])
//    {
//        NSNumber * isSensorOn = [userDefaults objectForKey:kSensorEnabledKey];
//        
//        //If sensor is off, show message saying "Sensor is off, turn it on?"
//        if(isSensorOn && [isSensorOn boolValue] == NO)
//        {
//            [self showSensorDisabledMessage];
//        }
//    }
    
    //Register for lock/unlock events
    [self registerAppforDetectLockState];
    
    return YES;
}



///*
// * @desc - Shows message saying "Sensor is off, turn it on?"
// */
//-(void)showSensorDisabledMessage
//{
//    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:nil
//                                                    message:kSensorOffMessage
//                                                   delegate:self
//                                          cancelButtonTitle:@"Cancel"
//                                          otherButtonTitles:@"Turn On", nil];
//    [alert show];
//}
//
//
//#pragma mark - AlertView Delegate Methods
//-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    //If Turn On button is tapped
//    if(buttonIndex == 1)
//    {
//        //Turn sensor on
//        NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
//        [userDefaults setValue:[NSNumber numberWithBool:YES] forKey:kSensorEnabledKey];
//        [userDefaults synchronize];
//        
//        Sensor * sensor = [Sensor sharedInstance];
//        [sensor startSensor];
//    }
//}

#pragma mark - App Life Cycle

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    
    //If user is a participant, stop sensor
    [self stopSensingData];
}


//starts when application switchs into backghround
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    BOOL isSensorOnFromSettings = [[[NSUserDefaults standardUserDefaults] valueForKey:kSensorEnabledKey] boolValue];
    
    //If user is a participant, start sensor
    if(isSensorOnFromSettings && self.userInfo && [self.userInfo.roleName isEqualToString:kRoleParticipant])
    {
        [self keepAlive];
    }
}

- (void) keepAlive {
    UIBackgroundTaskIdentifier backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
    }];
    
    //Stop timer
    if(self.backgroundTimer)
    {
        [self.backgroundTimer invalidate];
        self.backgroundTimer = nil;
    }
    
    //Set backgrond timer to run forever
    self.backgroundTimer = [NSTimer scheduledTimerWithTimeInterval:120
                                                       target:self
                                                     selector:@selector(updateLocation)
                                                     userInfo:nil
                                                      repeats:YES];
}

-(void)updateLocation
{
    static int i = 2;
    
    if((i % kBackgroundSensorDuration) == 0)
    {
        //Start sensing data
        Sensor * sensor = [Sensor sharedInstance];
        if(!sensor.isSensorRunning)
        {
            [sensor startSensor];
            
            [sensor performSelector:@selector(stopSensor) withObject:nil afterDelay:10];
            
        }
    }
    
    NSLog(@"Background Task %d", i);
    
    //Increment i
    i += 2;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    //Stop timer
    if(self.backgroundTimer)
    {
        [self.backgroundTimer invalidate];
        self.backgroundTimer = nil;
    }
    
    //If user is a participant, stop sensor
    //[self stopSensingData];
    Sensor * sensor = [Sensor sharedInstance];
    [NSObject cancelPreviousPerformRequestsWithTarget:sensor];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    //If user is a participant, start sensor
    [self startSensingData];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.qcri.QatarSense" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"QatarSense" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"QatarSense.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (BOOL)saveContext {
    
    BOOL isSaved = NO;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            //abort();
        }
        else
        {
            isSaved = YES;
        }
    }
    
    return isSaved;
}

-(void)registerAppforDetectLockState {
    
    int notify_token;
    notify_register_dispatch("com.apple.springboard.lockstate", &notify_token,dispatch_get_main_queue(), ^(int token) {
        
        uint64_t state = UINT64_MAX;
        notify_get_state(token, &state);
        
        if(state == 0) {
            NSLog(@"unlock device");
            [self startSensingData];
            [self performSelector:@selector(stopSensingData) withObject:nil afterDelay:10];
            
        } else {
            NSLog(@"lock device");
        }
        
        NSLog(@"com.apple.springboard.lockstate = %llu", state);
    });
}

-(void)startSensingData
{
    //If user is a participant, start sensor
    if(self.userInfo && [self.userInfo.roleName isEqualToString:kRoleParticipant])
    {
        //Start sensing data
        Sensor * sensor = [Sensor sharedInstance];
        if(!sensor.isSensorRunning)
        {
            [sensor startSensor];
        }
    }
}

-(void)stopSensingData
{
    //If user is a participant, stop sensor
    if(self.userInfo && [self.userInfo.roleName isEqualToString:kRoleParticipant])
    {
        //Start sensing data
        Sensor * sensor = [Sensor sharedInstance];
        if(sensor.isSensorRunning)
        {
            [sensor stopSensor];
        }
    }
}


@end
