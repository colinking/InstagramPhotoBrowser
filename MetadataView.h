//
//  MetadataView.h
//  Photo Bombers
//
//  Created by Colin on 7/15/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LikesTableView.h"
#import "CommentsTableView.h"

@class DetailViewController;

@interface MetadataView : UIView

@property (nonatomic) NSDictionary *photo;
@property (nonatomic) DetailViewController *detailViewController;
@property (nonatomic) LikesTableView *likesTableView;
@property (nonatomic) CommentsTableView *commentsTableView;



@end
