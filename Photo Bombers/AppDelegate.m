//
//  AppDelegate.m
//  Photo Bombers
//
//  Created by Colin on 7/11/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import "AppDelegate.h"
#import "PhotosViewController.h"
#import <SimpleAuth/SimpleAuth.h>
#import "SWRevealViewController.h"
#import "SideBarTableViewController.h"

@interface AppDelegate()<SWRevealViewControllerDelegate>
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
//    [NSThread sleepForTimeInterval:1.5];
    
    SimpleAuth.configuration[@"instagram"] = @{
       @"client_id": @"6c38de5d4a744217b0eacaa982026bd3",
       SimpleAuthRedirectURIKey: @"photobombers://auth/instagram"
    };
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    //The main content, in this case the photo viewer
    PhotosViewController *photosViewController = [[PhotosViewController alloc] init];
    
    //The side bar
	SideBarTableViewController *sideBarTableViewController = [[SideBarTableViewController alloc] init];
    sideBarTableViewController.photosViewController = photosViewController;
    photosViewController.sideBarTableViewController = sideBarTableViewController;
    UINavigationController *rearNavigationController = [[UINavigationController alloc] initWithRootViewController:sideBarTableViewController];
	UINavigationController *frontNavigationController = [[UINavigationController alloc] initWithRootViewController:photosViewController];
	[frontNavigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Futura" size:18], NSFontAttributeName, nil]];
	SWRevealViewController *revealController = [[SWRevealViewController alloc] initWithRearViewController:rearNavigationController frontViewController:frontNavigationController];
    revealController.delegate = self;
    
    self.revealController = revealController;
    
    //Style the nav bar
    UINavigationBar *navBar = frontNavigationController.navigationBar;
    navBar.barTintColor = [UIColor colorWithRed:242.0/255.0 green:122.0/255.0 blue:87.0/255.0 alpha:1.0];
    navBar.barStyle = UIBarStyleBlackOpaque;
    
    self.window.rootViewController = revealController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Reveal Controller Methods

- (BOOL)revealControllerPanGestureShouldBegin:(SWRevealViewController *)revealController {
//    NSLog(@"%f", [[revealController panGestureRecognizer] locationInView:self.window.rootViewController.view].x);
    return NO;
}

@end
