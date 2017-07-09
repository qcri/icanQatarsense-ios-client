//
//  UIView+BorderStuff.m
//  QatarSense
//
//  Created by Ravi Chaudhary on 15/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import "UIView+BorderStuff.h"

@implementation UIView (BorderStuff)

@dynamic borderColor,borderWidth,cornerRadius;

-(void)setBorderColor:(UIColor *)borderColor{
    [self.layer setBorderColor:borderColor.CGColor];
}

-(void)setBorderWidth:(CGFloat)borderWidth{
    [self.layer setBorderWidth:borderWidth];
}

-(void)setCornerRadius:(CGFloat)cornerRadius{
    [self.layer setCornerRadius:cornerRadius];
}


@end
