//
//  PresentDetailTransition.h
//  Photo Bombers
//
//  Created by Colin on 7/11/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PresentDetailTransition : NSObject <UIViewControllerAnimatedTransitioning>

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext;
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext;

@end
