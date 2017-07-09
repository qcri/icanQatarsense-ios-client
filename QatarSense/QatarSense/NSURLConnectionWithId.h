//
//  NSURLConnectionWithId.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 09/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLConnectionWithId : NSURLConnection


@property (nonatomic) NSInteger connectionId;

//Methods
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately connectionId:(NSUInteger)connectionId;

@end
