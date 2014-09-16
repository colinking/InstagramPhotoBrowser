//
//  PhotosViewController.m
//  Photo Bombers
//
//  Created by Colin on 7/11/14.
//  Copyright (c) 2014 Colin King. All rights reserved.
//

#import "PhotosViewController.h"
#import "PhotoCell.h"
#import "DetailViewController.h"
#import "PresentDetailTransition.h"
#import "DismissDetailTransition.h"
#import <SimpleAuth/SimpleAuth.h>
#import <SSKeychain/SSKeychain.h>
#import "SWRevealViewController.h"
#import "ColinsUtilities.h"
#import "PhotoController.h"
#import "SearchData.h"
#import "PhotoHeaderView.h"

@interface PhotosViewController () <UIViewControllerTransitioningDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) NSInteger indexToReload; //index at which new images should be pulled
@property (nonatomic) NSString *nextPageUrl;
@property (nonatomic) PhotoHeaderView *header;
@end

@implementation PhotosViewController {
    UIImage *pictureLoadingError;
}


- (instancetype)init {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(106.0, 106.0);
    layout.minimumInteritemSpacing = 1.0;
    layout.minimumLineSpacing = 1.0;
    layout.headerReferenceSize = CGSizeMake(0, 107);
//    layout.footerReferenceSize = CGSizeMake(0, 44);
    return (self = [super initWithCollectionViewLayout:layout]);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.selectedSearchTermData = [[SearchData alloc] init];
    self.selectedSearchTermData.title = [PhotoController feedNames][0];
    self.selectedSearchTermData.section = 0;
    self.title = self.selectedSearchTermData.title;
    self.photos = [[NSMutableOrderedSet alloc] init];
    self.url = [PhotoController getUrlForText:self.selectedSearchTermData.title section:self.selectedSearchTermData.section];
    
    self.revealController = [self revealViewController];
    
    [self.revealController panGestureRecognizer];
    [self.revealController tapGestureRecognizer];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reload"] style:UIBarButtonItemStyleBordered target:self action:@selector(refresh)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStyleBordered target:self.revealController action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem.tintColor = [UIColor whiteColor];
    
    self.collectionView.dataSource = self;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
    //in case the collection view isn't long enough to require scrolling (thus preventing scroll-to-refresh)
    self.collectionView.alwaysBounceVertical = YES;
    
    [self.collectionView registerClass:[PhotoCell class] forCellWithReuseIdentifier:@"photo"];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView"];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    pictureLoadingError = [UIImage imageNamed:@"error"];
    
    self.indexToReload = 11;
    self.fetchingMorePhotos = NO;
    
    UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showDetailView:)];
    press.minimumPressDuration = 0.3;
    [self.collectionView addGestureRecognizer:press];
    self.needsFreshReload = NO;
    
    [self refresh];
}

- (void)refresh {
    if(self.fetchingMorePhotos) {
        if(self.nextPageUrl)
            self.url = self.nextPageUrl;
        else
            NSLog(@"Next page url is empty");
    }
    if(!self.url) {
        self.url = [PhotoController getUrlForText:self.selectedSearchTermData.title section:self.selectedSearchTermData.section];
    }
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [[NSURL alloc] initWithString:self.url];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        NSData *data = [[NSData alloc] initWithContentsOfURL:location];
        if(!data) {
            //Do no data stuff
            
            NSLog(@"NO DATA. Response: %@", response);
            self.photos = [[NSMutableOrderedSet alloc] init];
        } else {
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            self.nextPageUrl = [responseDictionary valueForKeyPath:@"pagination.next_url"];
            
            if(self.needsFreshReload) {
                self.photos = [[NSMutableOrderedSet alloc] init];
                self.needsFreshReload = NO;
            }
            
            //Check if the photo is already in the collection. If so, replace it with the updated version.
            NSArray *photoData = [responseDictionary valueForKeyPath:@"data"];
            for (int photoIndex = 0; photoIndex < [photoData count]; photoIndex++) {
                for(int collectionIndex = 0; collectionIndex < [self.photos count]; collectionIndex++) {
                    if([self.photos[collectionIndex][@"id"] isEqualToString:photoData[photoIndex][@"id"]]) {
                        self.photos[collectionIndex] = photoData[photoIndex];
                        continue;
                    }
                }
            }
            
            [self.photos addObjectsFromArray:photoData];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.indexToReload = self.photos.count - 9;
            if(self.indexToReload < 15) self.indexToReload = 15;
            self.url = nil;
            self.fetchingMorePhotos = NO;
            [self.collectionView reloadData];
            [self.refreshControl endRefreshing];
        });
    }];
    [task resume];
}

#pragma mark - Collection View methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"photo" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor grayColor];
    cell.photo = self.photos[indexPath.row];
    return cell;
}

- (void)showDetailView:(UILongPressGestureRecognizer *) sender {
    if(sender.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [sender locationInView:self.collectionView];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
        if(indexPath) {
            NSDictionary *photo = self.photos[indexPath.row];
            DetailViewController *viewController = [[DetailViewController alloc] init];
            viewController.modalPresentationStyle = UIModalPresentationCustom;
            viewController.transitioningDelegate = self;
            viewController.photo = photo;
            viewController.photosViewController = self;
            viewController.indexPath = indexPath;
            
            viewController.photo = photo;
            [self presentViewController:viewController animated:YES completion:nil];
        }
    }
}

#pragma mark - Scroll/Load Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(self.fetchingMorePhotos) return;
    NSArray *indexPaths = self.collectionView.indexPathsForVisibleItems;
    for (NSIndexPath *indexPath in indexPaths) {
        if(indexPath.item >= self.indexToReload) {
            self.fetchingMorePhotos = YES;
            [self refresh];
            return;
        }
    }
}

#pragma mark - Methods for Footer/Header

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        UICollectionReusableView *headerview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        //Shrink the bounds so that there is one pixel of space between the header and pics
        CGRect headerBounds = headerview.bounds;
        headerBounds.size.height = headerBounds.size.height - 1;
        self.header = [[PhotoHeaderView alloc] initWithFrame:headerBounds];
        self.header.userName = self.selectedSearchTermData.title;
        [headerview addSubview:self.header];
        reusableview = headerview;
    }
    
//    if (kind == UICollectionElementKindSectionFooter) {
//        UICollectionReusableView *footerview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
//        UITextView *footer = [[UITextView alloc] initWithFrame:footerview.bounds];
//        footer.text = @"No More Photos";
//        footer.textAlignment = NSTextAlignmentCenter;
//        footer.textColor = [UIColor blackColor];
//        footer.font = [UIFont fontWithName:@"Helvetica" size:20];
//        [footerview addSubview:footer];
//        reusableview = footerview;
//    }
    
    return reusableview;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    //Hide the header unless the page is a user page
    if([[self.title substringToIndex:1] isEqualToString:@"@"] || [self.title isEqualToString:@"Your Photos"])
        return CGSizeMake(0, 107);
    else
        return CGSizeZero;
}


#pragma mark - Methods for initializing custom transitions for detail view

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return [[PresentDetailTransition alloc] init];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return [[DismissDetailTransition alloc] init];
}

#pragma mark - Colors

+ (UIColor *)darkTextColor {
	return [UIColor colorWithRed:0.949f green:0.510f blue:0.380f alpha:1.0f];
}


+ (UIColor *)lightTextColor {
	return [UIColor colorWithRed:0.973f green:0.753f blue:0.686f alpha:1.0f];
}

+ (UIColor *)textColorWhenLiked {
	return [UIColor colorWithRed:0.8f green:0.4f blue:0.4f alpha:1.0f];
}

+ (UIColor *)heartColorWhenLiked {
	return [UIColor colorWithRed:1.0f green:0.4f blue:0.4f alpha:1.0f];
}

+ (UIColor *)avatarBorderColorForLikedUser {
    return [UIColor colorWithRed:0.949f green:0.4f blue:0.3f alpha:1.0f];
}


@end
