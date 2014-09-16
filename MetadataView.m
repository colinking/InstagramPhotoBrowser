//
//  MetadataView.m
//  Photo Bombers
//
//  Created by Colin on 7/15/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import "MetadataView.h"
#import "PhotoController.h"
#import "PhotosViewController.h"
#import "SearchData.h"
#import "DetailViewController.h"
#import "SideBarTableViewController.h"
#import "PhotoCell.h"
#import <SAMCategories/NSDate+SAMAdditions.h>
#import "UIImage+StackBlur.h"

@interface MetadataView ()
@property (nonatomic) UIImageView *avatarImageView;
@property (nonatomic) UIButton *usernameButton;
@property (nonatomic) UIButton *timeButton;
@property (nonatomic) UIButton *likesButton;
@property (nonatomic) UIButton *commentsButton;
@property (nonatomic) UIImage *backupImage;
@property (nonatomic) UIView *backgroundTint;
@end


@implementation MetadataView

- (void)setPhoto:(NSDictionary *)photo {
    _photo = photo;
    NSDate *createdAt = [NSDate dateWithTimeIntervalSince1970:[_photo[@"created_time"] doubleValue]];
    [self.timeButton setTitle:[createdAt sam_briefTimeInWords] forState:UIControlStateNormal];
    
    //set everything else
    [PhotoController avatarForPhoto:self.photo completion:^(UIImage *image) {
        _avatarImageView.image = image;
    }];
    
    //change color of like button depending on whether it is liked or not (and set title)
    [self updateLikeButton];
    [self.commentsButton setTitle:[NSNumberFormatter localizedStringFromNumber:self.photo[@"comments"][@"count"] numberStyle:NSNumberFormatterDecimalStyle] forState:UIControlStateNormal];
    [self.usernameButton setTitle:_photo[@"user"][@"username"] forState:UIControlStateNormal];
}

#pragma mark - Actions

- (void)openUser:(id)sender {
    //dismiss detail view controller
    [self.detailViewController close];
    PhotosViewController *photosViewController = self.detailViewController.photosViewController;
    //show their feed
    photosViewController.url = nil;
    photosViewController.title = [NSString stringWithFormat:@"@%@", self.usernameButton.titleLabel.text];
    
    //add username to recents list
    [photosViewController.sideBarTableViewController addToRecents:photosViewController.title];
    
    [photosViewController.sideBarTableViewController.tableView reloadData];
    photosViewController.selectedSearchTermData.title = photosViewController.title;
    photosViewController.selectedSearchTermData.section = 1;
    photosViewController.needsFreshReload = YES;
    [photosViewController refresh];
    CGFloat compensateHeight = -([photosViewController navigationController].navigationBar.bounds.size.height+[UIApplication sharedApplication].statusBarFrame.size.height);
    [photosViewController.collectionView setContentOffset:CGPointMake(0, compensateHeight) animated:YES];
}

- (void)openPhoto:(id)sender {
    
}
- (void)likePhoto:(id)sender {
    //Prepare to make a request to like/unlike the photo
    NSURLSession *session = [NSURLSession sharedSession];
    NSString *urlString = [PhotoController getLikeUrlForPhoto:self.photo];
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    //check if the photo is already liked
    if([self.photo[@"user_has_liked"] boolValue]) {
        request.HTTPMethod = @"DELETE";
    } else {
        request.HTTPMethod = @"POST";
    }
    //Send the request
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if([(NSHTTPURLResponse *)response statusCode] != 200) {
//            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Uhoh!" message:[NSString stringWithFormat:@"An error occured.\nStatus Code: %ld\nPlease try again later!", (long)[(NSHTTPURLResponse *)response statusCode]] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert show];
            });
        } else {
            //Refresh the photo object
            NSURLSession *session = [NSURLSession sharedSession];
            //Get the URL to get a refreshed copy of the photo dictionary
            NSURL *url = [[NSURL alloc] initWithString:[PhotoController getPhotoDownloadUrl:self.photo]];
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
            NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                NSData *data = [[NSData alloc] initWithContentsOfURL:location];
                if(data) {
                    NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        self.photo = responseDictionary[@"data"];
                        
                        //update the photo stored in the photosviewcontroller instance
                        [self.detailViewController.photosViewController.photos replaceObjectAtIndex:self.detailViewController.indexPath.row withObject:self.photo];
                        [self updateLikeButton];
                        [self.detailViewController.photosViewController refresh];
                    });
                }
            }];
            [task resume];
        }
    }];
    [task resume];
}

- (void)toggleLikeTable:(UILongPressGestureRecognizer *) sender {
    if(sender.state == UIGestureRecognizerStateBegan) {
        if(self.likesTableView == nil) {
            self.likesTableView = [[LikesTableView alloc] init];
            self.likesTableView.photo = self.photo;
            self.likesTableView.metadataView = self;
            [self.detailViewController.view addSubview:self.likesTableView.view];
        } else {
            [self.likesTableView removeFromSuperviewAnimated];
        }
    }
}

- (void)processLongPressCommentsTable: (UILongPressGestureRecognizer *) sender {
    if(sender.state == UIGestureRecognizerStateBegan) {
        [self toggleCommentsTable:nil];
    }
}

- (void)toggleCommentsTable:(id) sender {
    if(self.commentsTableView == nil) {
        self.backupImage = self.detailViewController.imageView.image;
        self.commentsTableView = [[CommentsTableView alloc] init];
        self.commentsTableView.photo = self.photo;
        self.commentsTableView.metadataView = self;
        [self.detailViewController.view addSubview:self.commentsTableView.view];
        self.detailViewController.imageView.image = [self.backupImage stackBlur:20];
        self.backgroundTint = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
        self.backgroundTint.backgroundColor = [UIColor colorWithRed:0.6 green:0.3 blue:0.3 alpha:0.0];
        [self.detailViewController.imageView addSubview:self.backgroundTint];
        [UIView animateWithDuration:0.2 delay:0.1 usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options:kNilOptions animations:^{
            self.backgroundTint.alpha = 0.6;
        } completion:nil ];
    } else {
        [self.commentsTableView removeFromSuperviewAnimated];
        [self.backgroundTint removeFromSuperview];
        self.detailViewController.imageView.image = self.backupImage;
    }
}

#pragma mark - UIView

- (instancetype)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[self addSubview:self.usernameButton];
		[self addSubview:self.avatarImageView];
		[self addSubview:self.timeButton];
		[self addSubview:self.likesButton];
		[self addSubview:self.commentsButton];
	}
	return self;
}


- (CGSize)sizeThatFits:(CGSize)size {
	return CGSizeMake(320.0f, 400.0f);
}


#pragma mark - UIControls

- (UIImageView *)avatarImageView {
	if (!_avatarImageView) {
		_avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10.0f, 0.0f, 32.0f, 32.0f)];
		_avatarImageView.layer.cornerRadius = 16.0f;
		_avatarImageView.layer.borderColor = [PhotosViewController darkTextColor].CGColor;
		_avatarImageView.layer.borderWidth = 1.0f;
		_avatarImageView.layer.masksToBounds = YES;
		_avatarImageView.userInteractionEnabled = NO;
	}
	return _avatarImageView;
}


- (UIButton *)usernameButton {
	if (!_usernameButton) {
		_usernameButton = [[UIButton alloc] initWithFrame:CGRectMake(47.0f, 0.0f, 200.0f, 32.0f)];
		_usernameButton.titleLabel.font = [UIFont fontWithName:@"Futura" size:14];
		_usernameButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        
		UIColor *textColor = [PhotosViewController darkTextColor];
		[_usernameButton setTitleColor:textColor forState:UIControlStateNormal];
		[_usernameButton setTitleColor:[textColor colorWithAlphaComponent:0.5f] forState:UIControlStateHighlighted];
		[_usernameButton addTarget:self action:@selector(openUser:) forControlEvents:UIControlEventTouchUpInside];
	}
	return _usernameButton;
}


- (UIButton *)timeButton {
	if (!_timeButton) {
		_timeButton = [[UIButton alloc] initWithFrame:CGRectMake(230.0f, 0.0f, 80.0f, 32.0f)];
		_timeButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
		[_timeButton setImage:[UIImage imageNamed:@"time"] forState:UIControlStateNormal];
		_timeButton.adjustsImageWhenHighlighted = NO;
		_timeButton.imageEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 6.0f);
		_timeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _timeButton.userInteractionEnabled = NO;
        _timeButton.adjustsImageWhenHighlighted = YES;
		UIColor *textColor = [PhotosViewController lightTextColor];
		[_timeButton setTitleColor:textColor forState:UIControlStateNormal];
	}
	return _timeButton;
}


- (UIButton *)likesButton {
	if (!_likesButton) {
		_likesButton = [[UIButton alloc] initWithFrame:CGRectMake(10.0f, 360.0f, 80.0f, 40.0f)];
		_likesButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        UIImage *image = [UIImage imageNamed:@"like"];
        image= [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		[_likesButton setImage:image forState:UIControlStateNormal];
		_likesButton.adjustsImageWhenHighlighted = YES;
		_likesButton.imageEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 6.0f);
        _likesButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        UIColor *textColor;
        textColor = [PhotosViewController lightTextColor];
		[_likesButton setTitleColor:textColor forState:UIControlStateNormal];
		[_likesButton setTitleColor:[textColor colorWithAlphaComponent:0.5f] forState:UIControlStateHighlighted];
		[_likesButton addTarget:self action:@selector(likePhoto:) forControlEvents:UIControlEventTouchUpInside];
		UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(toggleLikeTable:)];
        longPress.minimumPressDuration = 0.3;
        [_likesButton addGestureRecognizer:longPress];
	}
	return _likesButton;
}


- (UIButton *)commentsButton {
	if (!_commentsButton) {
		_commentsButton = [[UIButton alloc] initWithFrame:CGRectMake(230.0f, 360.0f, 80.0f, 40.0f)];
		_commentsButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
		[_commentsButton setImage:[UIImage imageNamed:@"comment"] forState:UIControlStateNormal];
		_commentsButton.adjustsImageWhenHighlighted = NO;
		_commentsButton.imageEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 6.0f);
		_commentsButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        
		UIColor *textColor = [PhotosViewController lightTextColor];
		[_commentsButton setTitleColor:textColor forState:UIControlStateNormal];
		[_commentsButton setTitleColor:[textColor colorWithAlphaComponent:0.5f] forState:UIControlStateHighlighted];
		[_commentsButton addTarget:self action:@selector(toggleCommentsTable:) forControlEvents:UIControlEventTouchUpInside];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(processLongPressCommentsTable:)];
        longPress.minimumPressDuration = 0.3;
        [_commentsButton addGestureRecognizer:longPress];
	}
	return _commentsButton;
}





#pragma mark - Private

- (void) updateLikeButton {
    if([self.photo[@"user_has_liked"] boolValue]) {
        _likesButton.imageView.tintColor = [PhotosViewController heartColorWhenLiked];
    } else {
        _likesButton.imageView.tintColor = [PhotosViewController lightTextColor];
    }
    NSString *numAsString = [NSNumberFormatter localizedStringFromNumber:self.photo[@"likes"][@"count"] numberStyle:NSNumberFormatterDecimalStyle];
    [self.likesButton setTitle:[NSString stringWithFormat:@" %@", numAsString] forState:UIControlStateNormal];
}

@end
