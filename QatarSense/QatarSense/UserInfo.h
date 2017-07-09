//
//  UserInfo.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 09/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserInfo : NSObject
    @property (nonatomic, assign) NSInteger userId;
    @property (nonatomic, assign) NSInteger sessionId;
    @property (nonatomic, strong) NSString * authToken;
    @property (nonatomic, strong) NSString * userName;
    @property (nonatomic, strong) NSString * firstName;
    @property (nonatomic, strong) NSString * lastName;
    @property (nonatomic, strong) NSString * roleName;
    @property (nonatomic, strong) NSString * groupName;
@end
