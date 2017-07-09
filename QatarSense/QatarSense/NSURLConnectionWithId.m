//
//  NSURLConnectionWithId.m
//  QatarSense
//
//  Created by Ravi Chaudhary on 09/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import "NSURLConnectionWithId.h"

@implementation NSURLConnectionWithId

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately connectionId:(NSUInteger)connectionId
{
    if (self = [super initWithRequest:request delegate:delegate startImmediately:startImmediately])
    {
        self.connectionId = connectionId;
    }
    
    return self;
}

@end
