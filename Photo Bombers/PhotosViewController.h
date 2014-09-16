//
//  PhotosViewController.h
//  Photo Bombers
//
//  Created by Colin on 7/11/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SWRevealViewController, SearchData, SideBarTableViewController;

@interface PhotosViewController : UICollectionViewController

@property (nonatomic) SWRevealViewController *revealController;
@property (nonatomic) NSString *url;
@property (nonatomic) SearchData *selectedSearchTermData;
@property (nonatomic) NSMutableOrderedSet *photos;
@property (nonatomic) BOOL needsFreshReload;
@property (nonatomic) BOOL fetchingMorePhotos;
@property (nonatomic) SideBarTableViewController *sideBarTableViewController;

- (void)refresh;

+ (UIColor *)darkTextColor;
+ (UIColor *)lightTextColor;
+ (UIColor *)textColorWhenLiked;
+ (UIColor *)heartColorWhenLiked;
+ (UIColor *)avatarBorderColorForLikedUser;

@end
