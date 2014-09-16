//
//  ColinsUtilities.h
//  Photo Bombers
//
//  Created by Colin on 7/15/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ColinsUtilities : NSObject

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+ (UIImage *)imageWithColor:(UIColor *)color;

@end
