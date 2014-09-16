//
//  CommentsTableView.m
//  Photo Bombers
//
//  Created by Colin King on 8/31/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import "CommentsTableView.h"
#import "CommentsTableViewCell.h"
#import "PhotoController.h"
#import "PhotosViewController.h"
#import "ColinsUtilities.h"
#import "MetadataView.h"
#import "DetailViewController.h"
#import "SearchData.h"
#import "SideBarTableViewController.h"

@interface CommentsTableView () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic) UIPanGestureRecognizer *swipeRecognizer;
@property (nonatomic) CGPoint startLocation;
@property (nonatomic) BOOL isScrolling;
@end

@implementation CommentsTableView

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
    self.comments = [PhotoController getListOfCommentsForPhoto:self.photo];
    NSLog(@"%@", self.comments);
    self.view.autoresizesSubviews = NO;
    
    CGRect frame = CGRectMake(320, CGRectGetMidY(self.view.bounds) - 160, 320, 320);
    self.view.bounds = frame;
    self.tableView = [[UITableView alloc] initWithFrame:frame];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[CommentsTableViewCell class] forCellReuseIdentifier:@"commentCell" ];
    
    self.view = self.tableView;
    
    self.swipeRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    [self.tableView addGestureRecognizer:self.swipeRecognizer];
    self.swipeRecognizer.delegate = self;
    self.view.backgroundColor = [UIColor clearColor];
    self.tableView.userInteractionEnabled = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
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
    return [self.comments count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CommentsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"commentCell" forIndexPath:indexPath];
    
    if(cell == nil) {
        cell = [[CommentsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"commentCell"];
    }
    cell.textLabel.text = self.comments[indexPath.row][@"from"][@"username"];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont fontWithName:@"Futura" size:13];
    cell.detailTextLabel.text = self.comments[indexPath.row][@"text"];
    cell.detailTextLabel.font = [UIFont fontWithName:@"Futura" size:12];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.numberOfLines = 99;
    //Placeholder image
    cell.imageView.image = [ColinsUtilities imageWithColor:[UIColor whiteColor]];
    if(self.comments[indexPath.row][@"from"][@"profile_picture"] != nil) {
        [PhotoController avatarForUser:self.comments[indexPath.row][@"from"][@"username"] completion:^(UIImage *image) {
            cell.imageView.image = image;
        }];
    }
    
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(8, 5, 320, 9999)];
    label.numberOfLines=0;
    label.font = [UIFont fontWithName:@"Hero" size:12];
    label.text = self.comments[indexPath.row][@"text"];
    
    CGSize maximumLabelSize = CGSizeMake(320, 9999);
    CGSize expectedSize = [label sizeThatFits:maximumLabelSize];
    return MAX(expectedSize.height, 50);
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    CommentsTableViewCell *cell = (CommentsTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
//    NSString *userName = cell.detailTextLabel.text;
//    if(userName == nil)
//        userName = cell.textLabel.text;
//    PhotosViewController *photosViewController = self.metadataView.detailViewController.photosViewController;
//    photosViewController.url = nil;
//    photosViewController.title = userName;
//    photosViewController.selectedSearchTermData.title = userName;
//    photosViewController.selectedSearchTermData.section = 1;
//    photosViewController.needsFreshReload = YES;
//    photosViewController.fetchingMorePhotos = NO;
//    
//    //add username to recents list
//    [photosViewController.sideBarTableViewController addToRecents:userName];
//    
//    [photosViewController refresh];
//    [self.metadataView.detailViewController close];
//    CGFloat compensateHeight = -(self.navigationController.navigationBar.bounds.size.height+[UIApplication sharedApplication].statusBarFrame.size.height);
//    [photosViewController.collectionView setContentOffset:CGPointMake(0, compensateHeight) animated:YES];
//}

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
            finalPoint.x = (velocity.x < 0? -160 : 320 - 160);
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
        self.view.center = CGPointMake(-320+160, self.view.center.y);
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        self.metadataView.commentsTableView = nil;
    }];
}

@end
