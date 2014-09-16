//
//  LikesTableViewTableView.m
//  Photo Bombers
//
//  Created by Colin on 8/2/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import "LikesTableView.h"
#import "LikeTableViewCell.h"
#import "PhotoController.h"
#import "PhotosViewController.h"
#import "ColinsUtilities.h"
#import "MetadataView.h"
#import "DetailViewController.h"
#import "SearchData.h"
#import "SideBarTableViewController.h"

@interface LikesTableView () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic) UIPanGestureRecognizer *swipeRecognizer;
@property (nonatomic) CGPoint startLocation;
@property (nonatomic) BOOL isScrolling;
@end

@implementation LikesTableView

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.likes = [PhotoController getListOfLikesForPhoto:self.photo];
    
    self.view.autoresizesSubviews = NO;
    
    CGRect frame = CGRectMake(-320, CGRectGetMidY(self.view.bounds) - 160, 320, 320);
    self.view.bounds = frame;
    self.tableView = [[UITableView alloc] initWithFrame:frame];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[LikeTableViewCell class] forCellReuseIdentifier:@"likeCell" ];
    
    self.view = self.tableView;
    
    self.swipeRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    [self.tableView addGestureRecognizer:self.swipeRecognizer];
    self.swipeRecognizer.delegate = self;
    
    self.tableView.userInteractionEnabled = YES;
    
    self.isScrolling = NO;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:0.6 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.view.center = CGPointMake(160, self.view.center.y);
    } completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.likes count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LikeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"likeCell" forIndexPath:indexPath];
    
    if(cell == nil) {
        cell = [[LikeTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"likeCell"];
    }
    if(![self.likes[indexPath.row][@"full_name"] isEqualToString:@""]) {
        cell.textLabel.text = self.likes[indexPath.row][@"full_name"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", self.likes[indexPath.row][@"username"]];
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"@%@", self.likes[indexPath.row][@"username"]];
        cell.detailTextLabel.text = nil;
    }
    //Placeholder image
    cell.imageView.image = [ColinsUtilities imageWithColor:[UIColor whiteColor]];
    if(self.likes[indexPath.row][@"profile_picture"] != nil) {
        NSLog(@"%@", self.likes[indexPath.row][@"username"]);
        [PhotoController avatarForUser:self.likes[indexPath.row][@"username"] completion:^(UIImage *image) {
            cell.imageView.image = image;
        }];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LikeTableViewCell *cell = (LikeTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    NSString *userName = cell.detailTextLabel.text;
    if(userName == nil)
        userName = cell.textLabel.text;
    PhotosViewController *photosViewController = self.metadataView.detailViewController.photosViewController;
    photosViewController.url = nil;
    photosViewController.title = userName;
    photosViewController.selectedSearchTermData.title = userName;
    photosViewController.selectedSearchTermData.section = 1;
    photosViewController.needsFreshReload = YES;
    photosViewController.fetchingMorePhotos = NO;
    
    //add username to recents list
    [photosViewController.sideBarTableViewController addToRecents:userName];
    
    [photosViewController refresh];
    [self.metadataView.detailViewController close];
    CGFloat compensateHeight = -(self.navigationController.navigationBar.bounds.size.height+[UIApplication sharedApplication].statusBarFrame.size.height);
    [photosViewController.collectionView setContentOffset:CGPointMake(0, compensateHeight) animated:YES];
}

- (void)move:(UIPanGestureRecognizer *)sender {
    /*
     Adapted from: http://www.raywenderlich.com/6567/uigesturerecognizer-tutorial-in-ios-5-pinches-pans-and-more
     */
    
    CGPoint velocity = [sender velocityInView:self.view];
//    NSLog(@"pan recognized --- > %@  vy:%f, vx:%f", (abs(velocity.y) > abs(velocity.x)? @"Y":@"X"), velocity.y, velocity.x);
    if(abs(velocity.y) < abs(velocity.x)) {
        if(!self.isScrolling) {
            CGPoint translation = [sender translationInView:self.view];
            sender.view.center = CGPointMake(sender.view.center.x + translation.x,
                                                 sender.view.center.y);
            [sender setTranslation:CGPointMake(0, 0) inView:self.view];
            if(sender.view.center.x != CGRectGetMidX(self.view.bounds))
                self.tableView.scrollEnabled = NO;
        }
    } else if(sender.view.center.x == CGRectGetMidX(self.view.bounds)){
        self.isScrolling = YES;
    }
    if (sender.state == UIGestureRecognizerStateEnded) {
        self.isScrolling = NO;
        
        CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
        CGFloat slideMult = magnitude / 200;
//        NSLog(@"magnitude: %f, vy: %f, vx: %f, slideMult: %f", magnitude, velocity.y, velocity.x, slideMult);
        
        CGPoint finalPoint = CGPointMake(
                                         CGRectGetMidX(self.view.bounds),
                                          sender.view.center.y
                                         );
        BOOL removed = NO;
        if(abs(self.view.center.x - CGRectGetMidX(self.view.bounds)) > 100) {
            //remove from view
            removed = YES;
            finalPoint.x = (velocity.x < 0? -160 : 320 + 160);
        }
        [UIView animateWithDuration:MAX(MIN(slideMult*.5, .6), .2) delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            sender.view.center = finalPoint;
        } completion:^(BOOL finished) {
            if(removed) {
                [self.view removeFromSuperview];
                self.metadataView.likesTableView = nil;
            } else
                self.tableView.scrollEnabled = YES;
        }];
        
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)removeFromSuperviewAnimated {
    
    [UIView animateWithDuration:.7 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.view.center = CGPointMake(320+160, self.view.center.y);
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        self.metadataView.likesTableView = nil;
    }];
}

@end
