//
//  PhotoHeaderView.m
//  Photo Bombers
//
//  Created by Colin on 7/31/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import "PhotoHeaderView.h"
#import "PhotoController.h"
#import "PhotosViewController.h"

@interface PhotoHeaderView ()
@property (nonatomic) UIImageView *avatarImageView;
@property (nonatomic) UIButton *followButton;
@property (nonatomic) UIButton *followersButton;
@property (nonatomic) UIButton *followeesButton;
@property (nonatomic) UIButton *postsButton;

@end

static const float middleMargin = 10;
static const float topRowMargin = 2;
static const float outsideMargin = 6;
static const float buttonHeight = 32;
static const float topRowButtonWidth = ((106*2+1) - (2*topRowMargin) - (2*outsideMargin))/3;
static const float borderWidth = 1.2f;
static const float cornerRadius = 7.0f;
BOOL isFollowing = NO;

@implementation PhotoHeaderView

//photo, username, follows, followers, posts, follow/unfollow button

- (void)setUserName:(NSString *)userName {
    
    self.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
    
    NSDictionary *userInfo = [PhotoController getUserInfo];
    NSLog(@"Info about %@\n%@", userName, userInfo);
    NSString *selfUserName = [NSString stringWithFormat:@"@%@", [userInfo valueForKey:@"username"]];
    
    
    if([userName isEqualToString:@"Your Photos"]) {
        _userName = selfUserName;
    } else
        _userName = userName;
    
    if(selfUserName == _userName) {
        [self.followButton removeFromSuperview];
    } else {
        NSLog(@"DATA FOR %@", _userName);
        userInfo = [PhotoController getUserInfoForText:_userName];
        if(![self.followButton isDescendantOfView:self])
            [self addSubview:self.followButton];
    }
    
//    NSLog(@"username: %@", _userName);
//    NSLog(@"info: %@", [PhotoController getRelationshipInfoForText:_userName]);
//    NSLog(@"keys: %@", [[PhotoController getRelationshipInfoForText:_userName] allKeys]);
//    NSLog(@"value: %@", [[PhotoController getRelationshipInfoForText:_userName] valueForKey:@"outgoing_status"]);
    isFollowing = [[[PhotoController getRelationshipInfoForText:self.userName] valueForKey:@"outgoing_status"] isEqualToString:@"follows"];
    //set everything else
    [PhotoController avatarForUser:_userName completion:^(UIImage *image) {
        NSLog(@"Completion, image: %@", image);
        _avatarImageView.image = image;
    }];
    
    [self.followeesButton setTitle:[NSString stringWithFormat:@"%@\nFollowees", [userInfo valueForKeyPath:@"counts.followed_by"]] forState:UIControlStateNormal];
    [self.followersButton setTitle:[NSString stringWithFormat:@"%@\nFollowers", [userInfo valueForKeyPath:@"counts.follows"]] forState:UIControlStateNormal];
    [self.postsButton setTitle:[NSString stringWithFormat:@"%@\nPosts", [userInfo valueForKeyPath:@"counts.media"]] forState:UIControlStateNormal];
    [self updateFollowButton];
}

- (instancetype)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[self addSubview:self.avatarImageView];
        [self addSubview:self.followButton];
        [self addSubview:self.followersButton];
		[self addSubview:self.followeesButton];
		[self addSubview:self.postsButton];
	}
	return self;
}

- (UIImageView *)avatarImageView {
	if (!_avatarImageView) {
        static float width = 80;
		_avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(106/2-width/2, 106/2-width/2, width, width)];
		_avatarImageView.layer.cornerRadius = width/2;
		_avatarImageView.layer.borderColor = [PhotosViewController darkTextColor].CGColor;
		_avatarImageView.layer.borderWidth = 1.0f;
		_avatarImageView.layer.masksToBounds = YES;
		_avatarImageView.userInteractionEnabled = NO;
	}
	return _avatarImageView;
}

- (UIButton *)followButton {
    if (!_followButton) {
        float y = self.bounds.size.height/2 + middleMargin/2;
        _followButton = [[UIButton alloc] initWithFrame:CGRectMake(106+outsideMargin+1, y, (106*2+1)-2*outsideMargin, buttonHeight)];
//        _followButton.backgroundColor = [UIColor yellowColor];
        _followButton.titleLabel.font = [UIFont fontWithName:@"Futura" size:14];
        _followButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        
        _followButton.layer.cornerRadius = cornerRadius;
        _followButton.layer.borderWidth = borderWidth;
        _followButton.layer.masksToBounds = YES;
        _followButton.userInteractionEnabled = YES;
        [_followButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_followButton setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
        [_followButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [_followButton addTarget:self action:@selector(toggleFollow:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _followButton;
}

- (UIButton *)followersButton {
    if (!_followersButton) {
        float y = self.bounds.size.height/2 - (middleMargin/2 + buttonHeight);
		_followersButton = [[UIButton alloc] initWithFrame:CGRectMake((106+1)+outsideMargin+topRowButtonWidth+topRowMargin, y, topRowButtonWidth, buttonHeight)];
//        _followersButton.backgroundColor = [UIColor redColor];
		_followersButton.titleLabel.font = [UIFont fontWithName:@"Futura" size:12];
        _followersButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _followersButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _followersButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        _followersButton.layer.cornerRadius = cornerRadius;
        _followersButton.layer.borderColor = [[self class] buttonBorderColor].CGColor;
        _followersButton.layer.borderWidth = borderWidth;
        _followersButton.layer.masksToBounds = YES;
        
		UIColor *textColor = [UIColor blackColor];
		[_followersButton setTitleColor:textColor forState:UIControlStateNormal];
		[_followersButton setTitleColor:[textColor colorWithAlphaComponent:0.5f] forState:UIControlStateHighlighted];
		[_followersButton addTarget:self action:@selector(openFollowers:) forControlEvents:UIControlEventTouchUpInside];
	}
	return _followersButton;
}


- (UIButton *)followeesButton {
    if (!_followeesButton) {
        float y = self.bounds.size.height/2 - (middleMargin/2 + buttonHeight);
        _followeesButton = [[UIButton alloc] initWithFrame:CGRectMake((106+1)+outsideMargin+2*(topRowButtonWidth+topRowMargin), y, topRowButtonWidth, buttonHeight)];
//        _followeesButton.backgroundColor = [UIColor blueColor];
		_followeesButton.titleLabel.font = [UIFont fontWithName:@"Futura" size:12];
        _followeesButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _followeesButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _followeesButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        _followeesButton.layer.cornerRadius = cornerRadius;
        _followeesButton.layer.borderColor = [[self class] buttonBorderColor].CGColor;
        _followeesButton.layer.borderWidth = borderWidth;
        _followeesButton.layer.masksToBounds = YES;
        
		UIColor *textColor = [UIColor blackColor];
		[_followeesButton setTitleColor:textColor forState:UIControlStateNormal];
		[_followeesButton setTitleColor:[textColor colorWithAlphaComponent:0.5f] forState:UIControlStateHighlighted];
		[_followeesButton addTarget:self action:@selector(openFollowees:) forControlEvents:UIControlEventTouchUpInside];
	}
	return _followeesButton;
}


- (UIButton *)postsButton {
    if (!_postsButton) {
        float y = self.bounds.size.height/2 - (middleMargin/2 + buttonHeight);
        _postsButton = [[UIButton alloc] initWithFrame:CGRectMake((106+1)+outsideMargin, y, topRowButtonWidth, buttonHeight)];
//        _postsButton.backgroundColor = [UIColor greenColor];
		_postsButton.titleLabel.font = [UIFont fontWithName:@"Futura" size:12];
        _postsButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _postsButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _postsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        _postsButton.layer.cornerRadius = cornerRadius;
        _postsButton.layer.borderColor = [[self class] buttonBorderColor].CGColor;
        _postsButton.layer.borderWidth = borderWidth;
        _postsButton.layer.masksToBounds = YES;
        
		UIColor *textColor = [UIColor blackColor];
		[_postsButton setTitleColor:textColor forState:UIControlStateNormal];
		[_postsButton setTitleColor:[textColor colorWithAlphaComponent:0.5f] forState:UIControlStateHighlighted];
		[_postsButton addTarget:self action:@selector(openPosts:) forControlEvents:UIControlEventTouchUpInside];
	}
	return _postsButton;
}

- (void)toggleFollow:(id)sender {
    [PhotoController toggleFollowOfUser:self.userName andIsFollowing:isFollowing];
    isFollowing = !isFollowing;
    [self updateFollowButton];
}

- (void)openFollowers:(id)sender {
    
}

- (void)openFollowees:(id)sender {
    
}

- (void)openPosts:(id)sender {
    
}

+ (UIColor *)buttonBorderColor {
    return [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
}
+ (UIColor *)followButtonBorderColorGreen {
    return [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:0.5];
}
+ (UIColor *)followButtonBorderColorRed {
    return [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:0.5];
}

- (void)updateFollowButton {
    if(isFollowing) {
        _followButton.layer.borderColor = [[self class] followButtonBorderColorRed].CGColor;
        [self.followButton setTitle:@"Unfollow -" forState:UIControlStateNormal];
    } else {
        _followButton.layer.borderColor = [[self class] followButtonBorderColorGreen].CGColor;
        [self.followButton setTitle:@"Follow +" forState:UIControlStateNormal];
    }
}

@end
