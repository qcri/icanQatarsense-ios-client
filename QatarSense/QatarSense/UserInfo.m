//
//  UserInfo.m
//  QatarSense
//
//  Created by Ravi Chaudhary on 09/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import "UserInfo.h"

@implementation UserInfo


- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.userId = [coder decodeIntegerForKey:@"userId"];
        self.sessionId = [coder decodeIntegerForKey:@"sessionId"];
        self.userName  = [coder decodeObjectForKey:@"userName"];
        self.firstName  = [coder decodeObjectForKey:@"firstName"];
        self.lastName  = [coder decodeObjectForKey:@"lastName"];
        self.roleName  = [coder decodeObjectForKey:@"roleName"];
        self.groupName  = [coder decodeObjectForKey:@"groupName"];
        self.authToken  = [coder decodeObjectForKey:@"authToken"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:_userId forKey:@"userId"];
    [coder encodeInteger:_sessionId forKey:@"sessionId"];
    [coder encodeObject:_userName forKey:@"userName"];
    [coder encodeObject:_firstName forKey:@"firstName"];
    [coder encodeObject:_lastName forKey:@"lastName"];
    [coder encodeObject:_roleName forKey:@"roleName"];
    [coder encodeObject:_groupName forKey:@"groupName"];
    [coder encodeObject:_authToken forKey:@"authToken"];
    
    
}


@end
