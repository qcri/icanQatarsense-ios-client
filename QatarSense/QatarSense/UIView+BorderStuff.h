//
//  UIView+BorderStuff.h
//  QatarSense
//
//  Created by Ravi Chaudhary on 15/02/16.
//  Copyright © 2016 qcri. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (BorderStuff)

@property (nonatomic) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable CGFloat borderWidth;
@property (nonatomic) IBInspectable CGFloat cornerRadius;

@end
