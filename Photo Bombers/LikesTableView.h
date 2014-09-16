//
//  LikesTableViewTableView.h
//  Photo Bombers
//
//  Created by Colin on 8/2/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MetadataView;

@interface LikesTableView : UIViewController

@property (nonatomic) NSDictionary *photo;
@property (nonatomic, retain) NSArray *likes;
@property (nonatomic) MetadataView *metadataView;

- (void)removeFromSuperviewAnimated;

@end
