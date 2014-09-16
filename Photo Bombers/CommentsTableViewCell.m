//
//  CommentsTableViewCell.m
//  Photo Bombers
//
//  Created by Colin King on 8/31/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import "CommentsTableViewCell.h"
#import "ColinsUtilities.h"
#import "PhotosViewController.h"

@implementation CommentsTableViewCell

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.frame = CGRectMake(16, self.bounds.size.height/2-20, 40, 40);
    self.imageView.layer.cornerRadius = 16;
    self.imageView.layer.borderColor = [PhotosViewController avatarBorderColorForLikedUser].CGColor;
    self.imageView.layer.borderWidth = 1;
    self.imageView.layer.masksToBounds = YES;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
