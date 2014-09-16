//
//  DetailViewController.h
//  Photo Bombers
//
//  Created by Colin on 7/11/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhotosViewController;

@interface DetailViewController : UIViewController

@property (nonatomic) NSDictionary *photo;
@property (nonatomic) NSIndexPath *indexPath;
@property (nonatomic) PhotosViewController *photosViewController;
@property (nonatomic) UIImageView *imageView;

- (void)close;

@end
