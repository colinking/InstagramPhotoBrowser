//
//  LikeTableViewCell.m
//  Photo Bombers
//
//  Created by Colin on 8/2/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import "LikeTableViewCell.h"
#import "ColinsUtilities.h"
#import "PhotosViewController.h"

@implementation LikeTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.frame = CGRectMake(16, 4, 40, 40);
    self.imageView.layer.cornerRadius = 16;
    self.imageView.layer.borderColor = [PhotosViewController avatarBorderColorForLikedUser].CGColor;
    self.imageView.layer.borderWidth = 1;
    self.imageView.layer.masksToBounds = YES;
    
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
