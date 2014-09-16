//
//  PhotoController.h
//  Photo Bombers
//
//  Created by Colin on 7/11/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PhotoController : NSObject

+ (NSString *) accessToken;
+ (NSArray *) feedNames;

+ (void)imageForPhoto:(NSDictionary *)photo size:(NSString *)size completion:(void(^)(UIImage *image))completion;
+ (void)avatarForPhoto:(NSDictionary *)photo completion:(void(^)(UIImage *image))completion;
+ (void)avatarForUser:(NSString *)userName completion:(void (^)(UIImage *))completion;

+ (NSArray *)getListOfLikesForPhoto:(NSDictionary *)photo;
+ (NSArray *)getListOfCommentsForPhoto:(NSDictionary *)photo;
+ (NSString *)getUrlForText:(NSString *)text;
+ (NSString *)getUrlForText:(NSString *)text section:(NSInteger)section;
+ (NSString *)getLikeUrlForPhoto:(NSDictionary *)photo;
+ (NSString *)getPhotoDownloadUrl:(NSDictionary *)photo;
+ (NSDictionary *)getUserInfoForText: (NSString *)text;
+ (NSDictionary *)getUserInfo;
+ (NSDictionary *)getUserDataForText:(NSString *)text;
+ (NSDictionary *)getRelationshipInfoForText:(NSString *)text;
+ (void)toggleFollowOfUser:(NSString *)text andIsFollowing:(BOOL)isFollowing;
@end
