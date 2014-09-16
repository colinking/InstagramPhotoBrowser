//
//  DetailViewController.m
//  Photo Bombers
//
//  Created by Colin on 7/11/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import "DetailViewController.h"
#import "PhotoController.h"
#import "MetadataView.h"
#import "UIImage+StackBlur.h"
#import "UIImage+StackBlur.m"

@interface DetailViewController () <UIGestureRecognizerDelegate>
@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) MetadataView *metadataView;
@property (nonatomic) UIView *backgroundHighlight;
@end

@implementation DetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.9];
    self.view.clipsToBounds = YES;
    
    self.backgroundHighlight = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMidY(self.view.bounds)-209, 320, 409)];
    self.backgroundHighlight.backgroundColor = [UIColor colorWithRed:0.5 green:0.2 blue:0.3 alpha:0.9];
    self.backgroundHighlight.alpha = 0;
    [self.view addSubview:self.backgroundHighlight];
    
    self.metadataView = [[MetadataView alloc] initWithFrame:CGRectMake(0, 0, 320, 400)];
    self.metadataView.alpha = 0.0f;
    self.metadataView.photo = self.photo;
    self.metadataView.detailViewController = self;
    [self.view addSubview:self.metadataView];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, -320.0f, 320.0f, 320.0f)];
    self.imageView.backgroundColor = [UIColor colorWithWhite:0.5f alpha:0.7f];
    [self.view addSubview:self.imageView];
    
    [PhotoController imageForPhoto:self.photo size:@"standard_resolution" completion:^(UIImage *image) {
        self.imageView.image = image;
        [self toggleBlur];
    }];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    CGPoint point = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:self.imageView snapToPoint:point];
    [self.animator addBehavior:snap];
    
    self.metadataView.center = point;
    [UIView animateWithDuration:0.5 delay:0.6 usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options:kNilOptions animations:^{
        self.backgroundHighlight.alpha = 1.0f;
    } completion:nil ];
    [UIView animateWithDuration:0.7 delay:0.7 usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options:kNilOptions animations:^{
        self.metadataView.alpha = 1.0f;
    } completion:nil ];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([[[touch.view class] description] isEqualToString:@"UITableViewWrapperView"] ||
        [[[touch.view class] description] isEqualToString:@"UITableViewCellContentView"])
        return NO;
    return YES;
}

- (void)close {
    [self.animator removeAllBehaviors];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    CGPoint snapToPoint = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMaxY(self.view.bounds) + 200.0f);
    [self snapToPoint:snapToPoint];
}

- (void)toggleBlur {
    if(true) {
//        self.imageView.image = [self.imageView.image stackBlur:30];
    }
}

- (void)snapToPoint:(CGPoint) snapToPoint {
    UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:self.imageView snapToPoint:snapToPoint];
    UISnapBehavior *snapMV = [[UISnapBehavior alloc] initWithItem:self.metadataView snapToPoint:snapToPoint];
    UISnapBehavior *snapBV = [[UISnapBehavior alloc] initWithItem:self.backgroundHighlight snapToPoint:snapToPoint];
    if (self.metadataView.likesTableView) {
        UISnapBehavior *snapLV = [[UISnapBehavior alloc] initWithItem:self.metadataView.likesTableView.view snapToPoint:snapToPoint];
        [self.animator addBehavior:snapLV];
    }
    [self.animator addBehavior:snap];
    [self.animator addBehavior:snapMV];
    [self.animator addBehavior:snapBV];
}

@end
