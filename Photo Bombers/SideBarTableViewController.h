//
//  SideBarTableViewController.h
//  Photo Bombers
//
//  Created by Colin on 7/12/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhotosViewController;

@interface SideBarTableViewController : UITableViewController

@property (nonatomic) NSMutableArray *recents;
@property (nonatomic) NSMutableArray *searchResults;

@property (nonatomic) UISearchDisplayController *searchController;
@property (nonatomic) UISearchBar *searchBar;
@property (nonatomic) int selected;
@property (nonatomic) UIImage *selectedImage;
@property (nonatomic) PhotosViewController *photosViewController;

@property (nonatomic) BOOL sidebarIsShown;

- (void)addToRecents:(NSString *)text;
- (void)removeFromRecents:(NSString *)text;

@end
