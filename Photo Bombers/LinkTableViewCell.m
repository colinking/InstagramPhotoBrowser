//
//  LinkTableViewCell.m
//  Photo Bombers
//
//  Created by Colin on 7/15/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import "LinkTableViewCell.h"
#import "SideBarTableViewController.h"

@interface LinkTableViewCell ()
@end

@implementation LinkTableViewCell

- (void)awakeFromNib
{
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

//- (void)setFrame:(CGRect)frame {
//    frame.origin.x += inset;
//    frame.size.width -= 2 * inset;
//    [super setFrame:frame];
//}

@end
