//
//  PhotoCell.m
//  Photo Bombers
//
//  Created by Colin on 7/11/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import "PhotoCell.h"
#import "PhotoController.h"
#import <SSKeychain/SSKeychain.h>
#import <FontAwesomeKit/FAKFontAwesome.h>

@interface PhotoCell ()
@property (nonatomic) BOOL liked;
@property (nonatomic) UIImageView *bigHeartView;
@property (nonatomic) UIImageView *littleHeartView;
@end

@implementation PhotoCell

- (void)setPhoto:(NSDictionary *)photo {
    _photo = photo;
    self.liked = ([[photo[@"user_has_liked"] description]  isEqual: @"1"]);
    [PhotoController imageForPhoto:_photo size:@"thumbnail" completion:^(UIImage *image) {
        self.imageView.image = image;
    }];
    self.bigHeartView.alpha = 0.0;
    self.littleHeartView.alpha = 0.0;
    if(self.liked) {
        self.littleHeartView.alpha = 1.0;
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] init];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(like:)];
        tap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:tap];
        
        [self.contentView addSubview:self.imageView];
        
        FAKFontAwesome *likeIcon = [FAKFontAwesome heartIconWithSize:53];
        [likeIcon addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
        UIImage *likeImage = [likeIcon imageWithSize:CGSizeMake(106, 106)];
        self.bigHeartView = [[UIImageView alloc] initWithImage:likeImage];
        self.bigHeartView.alpha = 0.0;
        [self.imageView addSubview:self.bigHeartView];
        
        FAKFontAwesome *likedIcon = [FAKFontAwesome heartIconWithSize:20];
        [likedIcon addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
        likedIcon.drawingPositionAdjustment = UIOffsetMake(-40, -40);
        UIImage *likedImage = [likedIcon imageWithSize:CGSizeMake(106, 106)];
        self.littleHeartView = [[UIImageView alloc] initWithImage:likedImage];
        self.littleHeartView.alpha = 0.0;
        [self.imageView addSubview:self.littleHeartView];
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.contentView.bounds;
}



- (void)like:(UITapGestureRecognizer*)sender {
    NSURLSession *session = [NSURLSession sharedSession];
    NSString *urlString = [PhotoController getLikeUrlForPhoto:self.photo];
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    //Allows more requests/hour if signed headers used
    //[request addValue:[NSString stringWithFormat:@"%@|%@", ipAddress, appSecret] forHTTPHeaderField:@"X-Insta-Forwarded-For"];
    if(self.liked) {
        request.HTTPMethod = @"DELETE";
    } else {
        request.HTTPMethod = @"POST";
    }
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if([(NSHTTPURLResponse *)response statusCode] != 200) {
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSLog(@"\n data \n %@", dictionary);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Uhoh!" message:[NSString stringWithFormat:@"An error occured.\nStatus Code: %ld\nPlease try again later!", (long)[(NSHTTPURLResponse *)response statusCode]] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert show];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self likeCompletion];
                self.liked = !self.liked;
            });
        }
    }];
    [task resume];
}

- (void)likeCompletion {
    if(self.liked) {
        [self unlikeAnimation];
    } else {
        [self likeAnimation];
    }
}

- (void) likeAnimation {
    [UIView animateWithDuration:0.6 animations:^{
        
        self.bigHeartView.alpha = 1.0;
        
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0.4 options:kNilOptions animations:^{
            
            self.bigHeartView.alpha = 0.0;
            self.littleHeartView.alpha = 1.0;
            
        } completion:nil];
    }];
}

- (void) unlikeAnimation {
    [UIView animateWithDuration:0.6 animations:^{
        
        self.littleHeartView.alpha = 0.0;
        
    } completion:nil];
}
@end
