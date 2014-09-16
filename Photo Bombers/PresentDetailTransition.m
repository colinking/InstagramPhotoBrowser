//
//  PresentDetailTransition.m
//  Photo Bombers
//
//  Created by Colin on 7/11/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import "PresentDetailTransition.h"

static const double TIME_DURATION = 0.5;
//static const int TRANSLATION_DIST = 320;

@implementation PresentDetailTransition

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return TIME_DURATION;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *detail = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    detail.view.alpha = 0.0;
    
//    CGRect frame = containerView.bounds;
//    frame.origin.y += 20.0;
//    frame.size.height -= 20.0;
//    detail.view.frame = frame;
    [containerView addSubview:detail.view];
    
    [UIView animateWithDuration:TIME_DURATION animations:^{
        detail.view.alpha = 1.0;
//        detail.view.frame = toFrame;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];
}

@end
