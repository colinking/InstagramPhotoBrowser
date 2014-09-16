//
//  CommentsTableView.h
//  Photo Bombers
//
//  Created by Colin King on 8/31/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MetadataView;

@interface CommentsTableView : UIViewController

@property (nonatomic) NSDictionary *photo;
@property (nonatomic, retain) NSArray *comments;
@property (nonatomic) MetadataView *metadataView;

- (void)removeFromSuperviewAnimated;

@end
