//
//  PhotoController.m
//  Photo Bombers
//
//  Created by Colin on 7/11/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import "PhotoController.h"
#import <SAMCache/SAMCache.h>
#import <SSKeychain/SSKeychain.h>
#import <SimpleAuth/SimpleAuth.h>

BOOL isAsking = NO;
BOOL firstCall = YES;

@implementation PhotoController

+ (NSString *)accessToken {
//    if(firstCall) [SSKeychain deletePasswordForService:@"photoBombersInstagram" account:@"photoBombersInstagram-accessToken"];
    firstCall = NO;
    static NSString *accessToken = nil;
    accessToken = [SSKeychain passwordForService:@"photoBombersInstagram" account:@"photoBombersInstagram-accessToken"];
    if(accessToken == nil && !isAsking) {
        isAsking = YES;
        [SimpleAuth authorize:@"instagram" options:@{@"scope": @[@"likes", @"relationships"]} completion:^(NSDictionary *responseObject, NSError *error) {
            accessToken = responseObject[@"credentials"][@"token"];
            isAsking = NO;
            [SSKeychain setPassword:accessToken forService:@"photoBombersInstagram" account:@"photoBombersInstagram-accessToken"];
        }];
    }
    return accessToken;
}

+ (NSArray *) feedNames {
    static NSArray *feedNames = nil;
    
    if (feedNames == nil)
    {
        feedNames = [NSArray arrayWithObjects:@"My Instagram Feed", @"Liked", @"Popular Now", @"Your Photos", nil];
    }
    
    return feedNames;
}


+ (void)imageForPhoto:(NSDictionary *)photo size:(NSString *)size completion:(void(^)(UIImage *image))completion {
    if (photo == nil || size == nil || completion == nil) {
        return;
    }
    
    NSString *key = [[NSString alloc] initWithFormat:@"%@-%@", photo[@"id"], size];
    NSURL *url = [[NSURL alloc] initWithString:photo[@"images"][size][@"url"]];
	[self downloadURL:url key:key completion:completion];
}


+ (void)avatarForPhoto:(NSDictionary *)photo completion:(void(^)(UIImage *image))completion {
	if (photo == nil || completion == nil) {
        return;
    }
    
    NSString *key = [[NSString alloc] initWithFormat:@"avatar-%@", photo[@"user"][@"id"]];
    NSURL *url = [[NSURL alloc] initWithString:photo[@"user"][@"profile_picture"]];
	[self downloadURL:url key:key completion:completion];
}

+ (void)avatarForUser:(NSString *)userName completion:(void (^)(UIImage *))completion {
    if (userName == nil || completion == nil) {
        return;
    }
    
    NSDictionary *user = [self getUserDataForText:userName];
    NSString *key = [[NSString alloc] initWithFormat:@"avatar-%@", [self trimString:[[user valueForKeyPath:@"id"] description]]];
    NSURL *url = [[NSURL alloc] initWithString:[self trimString:[[user valueForKeyPath:@"profile_picture"] description]]];
	[self downloadURL:url key:key completion:completion];
}

+ (NSArray *)getListOfLikesForPhoto:(NSDictionary *)photo {
    NSString *urlString = [NSString stringWithFormat:@"https://api.instagram.com/v1/media/%@/likes?access_token=%@", photo[@"id"], self.accessToken];
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSData *likeData = [NSData dataWithContentsOfURL:url];
    NSDictionary *likeDataDictionary = [NSJSONSerialization JSONObjectWithData:likeData options:kNilOptions error:nil];
    return [likeDataDictionary valueForKeyPath:@"data"];
}

+ (NSArray *)getListOfCommentsForPhoto:(NSDictionary *)photo {
    NSString *urlString = [NSString stringWithFormat:@"https://api.instagram.com/v1/media/%@/comments?access_token=%@", photo[@"id"], self.accessToken];
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSData *commentData = [NSData dataWithContentsOfURL:url];
    NSDictionary *commentDataDictionary = [NSJSONSerialization JSONObjectWithData:commentData options:kNilOptions error:nil];
    return [commentDataDictionary valueForKeyPath:@"data"];
}

+ (NSString *)getUrlForText:(NSString *)text {
    return [self getUrlForText:text section:1];
}

+ (NSString *)getUrlForText:(NSString *)text section:(NSInteger)section {
    NSString *urlString = nil;
    if(section == 0) {
        //Feed Links
        switch ([self.feedNames indexOfObject:text]) {
            case 0:
                //Personal Feed
                urlString = [NSString stringWithFormat:@"https://api.instagram.com/v1/users/self/feed?"];
                break;
            case 1:
                //Liked Photos
                urlString = [NSString stringWithFormat:@"https://api.instagram.com/v1/users/self/media/liked?"];
                break;
            case 2:
                //Popular
                urlString = [NSString stringWithFormat:@"https://api.instagram.com/v1/media/popular?"];
                break;
            case 3:
                //Your Photos
                urlString = [NSString stringWithFormat:@"https://api.instagram.com/v1/users/self/media/recent/?"];
                break;
            default:
                NSLog(@"Error, NO URL: text: %@, index: %d", text, (int) [self.feedNames indexOfObject:text]);
        }
    } else {
        if([[text substringToIndex:1] isEqualToString:@"#"]) {
            urlString = [NSString stringWithFormat:@"https://api.instagram.com/v1/tags/%@/media/recent?", [text substringFromIndex:1]];
        } else if([[text substringToIndex:1] isEqualToString:@"@"]) {
            
            NSString *userId = [self getUserIdForText:text];
            
            urlString = [NSString stringWithFormat:@"https://api.instagram.com/v1/users/%@/media/recent/?", userId];
        } else {
            urlString = [NSString stringWithFormat:@"https://api.instagram.com/v1/tags/%@/media/recent?", text];
        }
    }
//    NSLog(@"\n\nURL REQUEST\nURL:%@\ntext: %@\nsection: %d\n\n", urlString, text, section);
    return [NSString stringWithFormat:@"%@access_token=%@&", urlString, self.accessToken];
}

+ (NSString *) getLikeUrlForPhoto:(NSDictionary *)photo {
    return [[NSString alloc] initWithFormat:@"https://api.instagram.com/v1/media/%@/likes?access_token=%@", photo[@"id"], self.accessToken];
}

#pragma mark - Helper methods

+ (NSString *)getUserIdForText:(NSString *)text {
    //Check the cache
    NSString *userId = [[SAMCache sharedCache] objectForKey:[NSString stringWithFormat:@"userId-%@", text]];
    if(userId)
        return userId;
    //Else fetch the user ID
    NSURL *userIdUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"https://api.instagram.com/v1/users/search?q=%@&access_token=%@&count=1", [text substringFromIndex:1], self.accessToken]];
    NSData *userIdData = [NSData dataWithContentsOfURL:userIdUrl];
    NSDictionary *userIdDictionary = [NSJSONSerialization JSONObjectWithData:userIdData options:kNilOptions error:nil];
    NSString *unformattedId = [[userIdDictionary valueForKeyPath:@"data.id"] description];
    //Get rid of the "()" and " " and "\n"
    userId = [self trimString:unformattedId];
    
    [[SAMCache sharedCache] setObject:userId forKey:[NSString stringWithFormat:@"userId-%@", text]];
    return userId;
}

+ (NSString *)getPhotoDownloadUrl:(NSDictionary *)photo {
    return [[NSString alloc] initWithFormat:@"https://api.instagram.com/v1/media/%@?access_token=%@", photo[@"id"], self.accessToken];
}

+ (NSDictionary *)getUserDataForText:(NSString *)text {
    NSURL *userUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"https://api.instagram.com/v1/users/search?q=%@&access_token=%@&count=1", [text stringByReplacingOccurrencesOfString:@"@" withString:@""], self.accessToken]];
    NSData *userData = [NSData dataWithContentsOfURL:userUrl];
    NSDictionary *userDictionary = [NSJSONSerialization JSONObjectWithData:userData options:kNilOptions error:nil];
    NSLog(@"%@", [userDictionary valueForKeyPath:@"data"]);
    return [userDictionary valueForKeyPath:@"data"];
}

+ (NSDictionary *)getUserInfoForText: (NSString *)text {
    NSURL *userUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"https://api.instagram.com/v1/users/%@?access_token=%@", [self getUserIdForText:text], self.accessToken]];
    NSData *userData = [NSData dataWithContentsOfURL:userUrl];
    NSDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:userData options:kNilOptions error:nil];
    return [userInfo valueForKeyPath:@"data"];
}

+ (NSDictionary *)getUserInfo {
    NSURL *userUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"https://api.instagram.com/v1/users/self?access_token=%@", self.accessToken]];
    NSData *userData = [NSData dataWithContentsOfURL:userUrl];
    NSDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:userData options:kNilOptions error:nil];
    NSLog(@"%@", userInfo);
    NSLog(@"%@", [userInfo valueForKeyPath:@"data"]);
    return [userInfo valueForKeyPath:@"data"];
}

+ (NSDictionary *)getRelationshipInfoForText:(NSString *)text {
    NSString *userId = [self getUserIdForText:text];
    NSURL *relationshipUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"https://api.instagram.com/v1/users/%@/relationship?access_token=%@", userId, self.accessToken]];
    NSData *relationshipData = [NSData dataWithContentsOfURL:relationshipUrl];
    NSDictionary *relationshipInfo = [NSJSONSerialization JSONObjectWithData:relationshipData options:kNilOptions error:nil];
    return [relationshipInfo valueForKey:@"data"];
}

+ (void)toggleFollowOfUser:(NSString *)text andIsFollowing:(BOOL)isFollowing{
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = nil;
    if(isFollowing) {
        url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"https://api.instagram.com/v1/users/%@/relationship?access_token=%@&action=unfollow", [self getUserIdForText:text], [PhotoController accessToken]]];
    } else {
        url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"https://api.instagram.com/v1/users/%@/relationship?access_token=%@&action=follow", [self getUserIdForText:text], [PhotoController accessToken]]];
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if([(NSHTTPURLResponse *)response statusCode] != 200) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Uhoh!" message:[NSString stringWithFormat:@"An error occured.\nStatus Code: %ld\nPlease try again later!", (long)[(NSHTTPURLResponse *)response statusCode]] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            NSLog(@"ERROR %@", error);
            NSLog(@"Response %@", response);
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert show];
            });
        }
    }];
    [task resume];
}
#pragma mark - Private

+ (void)downloadURL:(NSURL *)url key:(NSString *)key completion:(void(^)(UIImage *image))completion {
    UIImage *image = [[SAMCache sharedCache] imageForKey:key];
    if (image) {
        completion(image);
        return;
    }
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        NSData *data = [[NSData alloc] initWithContentsOfURL:location];
        UIImage *image = [[UIImage alloc] initWithData:data];
        [[SAMCache sharedCache] setImage:image forKey:key];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(image);
        });
    }];
    [task resume];
}

+ (NSString *)trimString:(NSString *)string {
    string = [[[[[string stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"(" withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""] stringByReplacingOccurrencesOfString:@"\"" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return string;
}


@end
