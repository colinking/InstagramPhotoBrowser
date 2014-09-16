//
//  SideBarTableViewController.m
//  Photo Bombers
//
//  Created by Colin on 7/12/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import "SideBarTableViewController.h"
#import "SWRevealViewController.h"
#import "ColinsUtilities.h"
#import "LinkTableViewCell.h"
#import "PhotosViewController.h"
#import "PhotoController.h"
#import "SearchData.h"
#import "BackgroundGradient.h"

#define UDRecentSearchs @"recentSearchs"

@interface SideBarTableViewController () <UISearchDisplayDelegate, UISearchBarDelegate, UIScrollViewDelegate, SWRevealViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, NSCoding> {
    BOOL isSearching;
}
@property (nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic) CGPoint startLocation;
@property (nonatomic) BOOL isScrolling;
@property (nonatomic) LinkTableViewCell *slidingCell;
@end

@implementation SideBarTableViewController

-(id)init {
    self = [super init];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.recents = [userDefaults objectForKey:UDRecentSearchs];
    if(self.recents == nil)
        self.recents = [NSMutableArray arrayWithObjects:@"#photobomb", @"@omgitshannahv", @"@colink96", @"@kylelikesbikes", @"@VOeLKSwagon", nil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];    
    isSearching = NO;
    self.selected = 0;
    
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
    self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchBar.delegate = self;
    self.searchBar.barStyle = 1;
    [self.searchBar setShowsCancelButton:YES animated:NO];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setFont:[UIFont fontWithName:@"Futura" size:14]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.9]];
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTintColor:[UIColor clearColor]];
    self.navigationItem.titleView = self.searchBar;
    self.navigationController.navigationBar.barTintColor = [[self class] tableViewColor];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.9];
    self.navigationController.navigationBar.translucent = YES;
    self.searchController = [[UISearchDisplayController alloc]
                        initWithSearchBar:self.searchBar contentsController:self];
    self.searchController.delegate = self;
    self.searchController.searchResultsDataSource = self;
    self.searchController.searchResultsDelegate = self;
    
//    CAGradientLayer *backgroundGradient = [BackgroundGradient blueGradient];
//    backgroundGradient.frame = self.view.bounds;
//    [self.tableView.layer insertSublayer:backgroundGradient atIndex:0];
    
    
    self.searchResults = [NSMutableArray array];
    
    [self.tableView registerClass:[LinkTableViewCell class] forCellReuseIdentifier:@"recent"];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnTableView:)];
    [self.tableView addGestureRecognizer:tap];
    
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
    [self.tableView addGestureRecognizer:self.panRecognizer];
    self.panRecognizer.delegate = self;
    
    self.tableView.backgroundColor = [[self class] tableViewColor];
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    
    self.isScrolling = NO;
    
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated {
    self.sidebarIsShown = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    //Clears the search query and fixes the table view
    self.searchBar.text = nil;
    isSearching = NO;
    [self.tableView reloadData];
}

- (void)setRecents:(NSMutableArray *)recents {
    _recents = recents;
    [self writeToUD];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(isSearching) {
        return 1;
    } else {
        return 2;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(isSearching)
        return @"";
    switch(section) {
        case 0:
            return @"Feed";
            break;
        case 1:
            return @"Recent Searches";
            break;
        default:
            NSLog(@"Section header not given");
            return @"";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(isSearching) {
        return [self.searchResults count];
    } else {
        switch (section) {
            case 0:
                return [[PhotoController feedNames] count];
            case 1:
                return [self.recents count];
            default:
                NSLog(@"Error, too many sections");
                return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"recent";
    LinkTableViewCell *cell = (LinkTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[LinkTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.9];
    [cell setSelectedBackgroundView:bgColorView];
    cell.textLabel.highlightedTextColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    
    if(isSearching){
        cell.textLabel.text = self.searchResults[indexPath.row];
    }
    else {
        switch (indexPath.section) {
            case 0:
                cell.textLabel.text = [PhotoController feedNames][indexPath.row];
                break;
            case 1:
                cell.textLabel.text = self.recents[indexPath.row];
                if(indexPath.row == self.selected) {
//                    cell.backgroundColor = [UIColor colorWithRed:255.0 / 255.0 green:219.0 / 255.0 blue:120.0 / 255.0 alpha:1.0];
//                    cell.backgroundView = [[UIImageView alloc] initWithImage:self.selectedImage];
                }
                break;
            default:
                NSLog(@"Error, too many sections");
        }
    }
    
    cell.textLabel.textColor = [UIColor lightGrayColor];
    cell.textLabel.font = [UIFont fontWithName:@"Futura" size:14.0];
//    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    cell.backgroundColor = [UIColor clearColor];
    

//    cell.backgroundColor = [UIColor darkGrayColor];
//    cell.textLabel.textColor = [UIColor whiteColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self transitionBackToCollection:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Background color
    view.tintColor = [[self class] tableViewColor];
    
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor whiteColor]];
    [header.textLabel setFont:[UIFont fontWithName:@"Futura" size:15]];
    // Another way to set the background color
    // Note: does not preserve gradient effect of original header
    // header.contentView.backgroundColor = [UIColor blackColor];
}

#pragma mark - Deleting Searches

//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    return YES;
//}
//
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        [self.recents removeObjectAtIndex:indexPath.row];
//        [self.tableView reloadData];
//    }
//}

#pragma mark - Helper Methods

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    isSearching = YES;
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.revealViewController setFrontViewPosition:FrontViewPositionRightMost animated:YES];
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.searchResults removeAllObjects];
    
    if([searchText length] != 0) {
        isSearching = YES;
        [self filterContentForSearchText:searchText scope:nil];
    }
    else {
        isSearching = NO;
    }
    [self.tableView reloadData];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    isSearching = NO;
    [self.searchBar setShowsCancelButton:YES animated:YES];
    [self.revealViewController setFrontViewPosition:FrontViewPositionRight animated:YES];
    [self addToRecents:searchBar.text];
    
    NSLog(@"%@", self.recents);
    [self.tableView reloadData];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", searchText];
    self.searchResults = [NSMutableArray arrayWithArray:[self.recents filteredArrayUsingPredicate:resultPredicate]];
}

- (void)didTapOnTableView:(UIGestureRecognizer*) recognizer {
    CGPoint tapLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:tapLocation];
    if (indexPath && !isSearching) {
        //we are in a tableview cell, let the gesture be handled by the view
        recognizer.cancelsTouchesInView = NO;
    } else {
        [self.searchDisplayController.searchBar resignFirstResponder];
        isSearching = NO;
        [self.searchBar setShowsCancelButton:YES animated:YES];
        [self.revealViewController setFrontViewPosition:FrontViewPositionRight animated:YES];
    }
}

- (void)transitionBackToCollection:(NSIndexPath *) indexPath {
    LinkTableViewCell *cell = (LinkTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    self.photosViewController.url = nil;
    self.photosViewController.title = cell.textLabel.text;
    self.photosViewController.selectedSearchTermData.title = cell.textLabel.text;
    self.photosViewController.selectedSearchTermData.section = indexPath.section;
    self.photosViewController.needsFreshReload = YES;
    self.sidebarIsShown = NO;
    [self.photosViewController refresh];
    CGFloat compensateHeight = -(self.navigationController.navigationBar.bounds.size.height+[UIApplication sharedApplication].statusBarFrame.size.height);
    [self.photosViewController.collectionView setContentOffset:CGPointMake(0, compensateHeight) animated:YES];
    [self.searchBar setShowsCancelButton:YES animated:YES];
    [self.revealViewController setFrontViewPosition:FrontViewPositionLeftSide animated:YES];
}

#pragma mark - Slide to Delete Methods

- (void)move: (UIPanGestureRecognizer *) sender {
    /*
     Adapted from: http://www.raywenderlich.com/6567/uigesturerecognizer-tutorial-in-ios-5-pinches-pans-and-more
     */
    
    NSIndexPath *indexPath = nil;
    if(self.slidingCell == nil) {
        indexPath = [self.tableView indexPathForRowAtPoint:[sender locationInView:self.tableView]];
        self.slidingCell = (LinkTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    } else {
        indexPath = [self.tableView indexPathForCell:self.slidingCell];
    }
    //Check if it is a feed item or if the selected point is in a header
    if(indexPath.section == 0 || !CGRectContainsPoint(self.slidingCell.bounds, [sender locationInView:self.tableView])) {
        self.slidingCell = nil;
        return;
    }
    CGPoint velocity = [sender velocityInView:self.view];
//    NSLog(@"pan recognized --- > %@  vy:%f, vx:%f", (abs(velocity.y) > abs(velocity.x)? @"Y":@"X"), velocity.y, velocity.x);
//    NSLog(@"Scroll Enabled: %hhd, isScrolling: %hhd, x: %f, midx: %f", self.tableView.isScrollEnabled, self.isScrolling, self.slidingCell.center.x, CGRectGetMidX(self.view.bounds));
    if(abs(velocity.y) > abs(velocity.x) && self.slidingCell.center.x == CGRectGetMidX(self.view.bounds)) {
        self.isScrolling = YES;
    } else {
        if(!self.isScrolling) {
            CGPoint translation = [sender translationInView:self.view];
            self.slidingCell.center = CGPointMake(self.slidingCell.center.x + translation.x,
                                                  self.slidingCell.center.y);
            [sender setTranslation:CGPointZero inView:self.view];
            if(self.slidingCell.center.x != CGRectGetMidX(self.view.bounds))
                self.tableView.scrollEnabled = NO;
        }
    }
    if (sender.state == UIGestureRecognizerStateEnded) {
        self.isScrolling = NO;
        CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
        CGFloat slideMult = magnitude / 200;
        //        NSLog(@"magnitude: %f, vy: %f, vx: %f, slideMult: %f", magnitude, velocity.y, velocity.x, slideMult);
        
        CGPoint finalPoint = CGPointMake(
                                         CGRectGetMidX(self.view.bounds),
                                         self.slidingCell.center.y
                                         );
        BOOL removed = NO;
        if(abs(self.slidingCell.center.x - CGRectGetMidX(self.view.bounds)) > 60) {
            //remove from view
            removed = YES;
            finalPoint.x = (velocity.x < 0? -160 : 320 + 160);
        }
        [UIView animateWithDuration:MAX(MIN(slideMult*.5, .6), .2) delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.slidingCell.center = finalPoint;
        } completion:^(BOOL finished) {
            if(removed) {
                [self.recents removeObjectAtIndex:indexPath.row];
                [self writeToUD];
                if(velocity.x > 0)
                    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
                else
                    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            } else
                self.tableView.scrollEnabled = YES;
            self.slidingCell = nil;
        }];
        
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES; //otherGestureRecognizer is your custom pan gesture
}

- (void)addToRecents:(NSString *)text {
    [self.recents removeObject:text];
    [self.recents insertObject:text atIndex:0];
    [self writeToUD];
}

- (void)removeFromRecents:(NSString *)text {
    [self.recents removeObject:text];
    [self writeToUD];
}

- (void)writeToUD {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:_recents forKey:UDRecentSearchs];
}

+ (UIColor *)tableViewColor {
    return [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
}

@end
