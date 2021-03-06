//
//  SCRMediaCollectionView.m
//  SecureReader
//
//  Created by N-Pex on 2015-03-20.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMediaCollectionView.h"
#import "SCRDatabaseManager.h"
#import "SCRAppDelegate.h"
#import "SCRMediaItem.h"
#import "SCRMediaCollectionViewDownloadView.h"

@interface SCRMediaCollectionViewItem : NSObject

@property (nonatomic, weak) SCRMediaItem *mediaItem;
@property (nonatomic, strong) UIView *view;
@property (nonatomic) BOOL downloading;
@property (nonatomic) BOOL downloaded;

@end

@implementation SCRMediaCollectionViewItem
@end

@interface SCRMediaCollectionView ()
@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;
@property (nonatomic, weak) SCRItem *item;
@property (nonatomic, strong) NSMutableArray *mediaItems;
@property (nonatomic, strong) dispatch_queue_t imageQueue;
@end

@implementation SCRMediaCollectionView

@synthesize contentView;
@synthesize pageControl;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        // Default values
        self.downloadViewHeight = 80;
        self.imageViewHeight = 200;
        
        self.mediaItems = [NSMutableArray array];
        
        [[NSBundle mainBundle] loadNibNamed:@"SCRMediaCollectionView" owner:self options:nil];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.contentView];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        _heightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:80];
        [self addConstraint:_heightConstraint];
        
        [(SwipeView*)contentView setBounces:NO];
    }
    return self;
}

- (void)dealloc
{
    if (self.imageQueue != nil)
    {
        self.imageQueue = nil;
    }
}

- (void) setItem:(SCRItem *)item
{
    if (_item != item)
    {
        _item = item;
        @synchronized(self.mediaItems)
        {
            [self.mediaItems removeAllObjects];
            [[SCRDatabaseManager sharedInstance].readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                [_item enumerateMediaItemsInTransaction:transaction block:^(SCRMediaItem *mediaItem, BOOL *stop) {
                    SCRMediaCollectionViewItem *item = [SCRMediaCollectionViewItem new];
                    item.mediaItem = mediaItem;
                    item.view = nil;
                    item.downloading = NO;
                    item.downloaded = [[SCRAppDelegate sharedAppDelegate].fileManager hasDataForPath:mediaItem.localPath];
                    [self.mediaItems addObject:item];
                }];
            }];
        }
    }
    [self updateHeight];
}

- (void)updateHeight
{
    NSInteger firstDownloaded = [self.mediaItems indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return ((SCRMediaCollectionViewItem *)obj).downloaded;
    }];
    
    if (firstDownloaded != NSNotFound)
    {
        self.heightConstraint.constant = [self imageViewHeight];
    }
    else if (self.showDownloadButtonIfNotLoaded && self.mediaItems.count > 0)
    {
        self.heightConstraint.constant = [self downloadViewHeight];
    }
    else
    {
        self.heightConstraint.constant = 0;
    }
}

- (void) createThumbnails:(BOOL)downloadIfNeeded
{
    if (_item != nil)
    {
        if (self.imageQueue == nil)
            self.imageQueue = dispatch_queue_create("ImageQueue",NULL);
        dispatch_async(self.imageQueue, ^{
            
            @synchronized(self.mediaItems)
            {
                for (SCRMediaCollectionViewItem *mediaItem in self.mediaItems)
                {
                    if (mediaItem.downloading)
                        continue;
                    if (mediaItem.downloaded && mediaItem.view != nil)
                        continue;
                    
                    if ([[SCRAppDelegate sharedAppDelegate].fileManager hasDataForPath:mediaItem.mediaItem.localPath])
                    {
                        [self mediaItemCreate:mediaItem];
                    }
                    else if (downloadIfNeeded)
                    {
                        [self mediaItemDownload:mediaItem];
                    }
                    else if (self.showDownloadButtonIfNotLoaded)
                    {
                        if (mediaItem.view == nil)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                CGRect frame = CGRectMake(0, 0, self.contentView.bounds.size.width, [self imageViewHeight]);
                                SCRMediaCollectionViewDownloadView *view = [[SCRMediaCollectionViewDownloadView alloc] initWithFrame:frame];
                                view.delegate = self;
                                mediaItem.view = view;
                                [(SwipeView *)self.contentView reloadData];
                            });
                        }
                    }
                }
            }
        });
    }
}

- (void) mediaItemCreate:(SCRMediaCollectionViewItem *)mediaItem
{
    [[SCRAppDelegate sharedAppDelegate].fileManager dataForPath:mediaItem.mediaItem.localPath completionQueue:self.imageQueue completion:^(NSData *data, NSError *error) {
        mediaItem.downloading = false;
        if (error == nil)
        {
            mediaItem.downloaded = true;
            UIImage *image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                [imageView setFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, [self imageViewHeight])];
                mediaItem.view = imageView;
                [(SwipeView *)self.contentView reloadData];
            });
        }
    }];
}

- (void) mediaItemDownload:(SCRMediaCollectionViewItem *)mediaItem
{
    mediaItem.downloading = YES;
    [[SCRAppDelegate sharedAppDelegate].mediaFetcher downloadMediaItem:mediaItem.mediaItem completionBlock:^(NSError *error) {
        mediaItem.downloading = NO;
        [[SCRAppDelegate sharedAppDelegate].fileManager dataForPath:mediaItem.mediaItem.localPath completionQueue:self.imageQueue   completion:^(NSData *data, NSError *error) {
            if (error == nil)
            {
                mediaItem.downloaded = true;
                UIImage *image = [UIImage imageWithData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                    mediaItem.view = imageView;
                    [imageView setFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, [self imageViewHeight])];
                    [(SwipeView *)self.contentView reloadData];
                    
                    UITableViewCell *cell = [self cellThisViewIsContainedIn];
                    UITableView *tableView = [self tableViewForCell:cell];
                    if (tableView != nil && cell != nil)
                    {
                        NSIndexPath *indexPath = [tableView indexPathForCell:cell];
                        if (indexPath != nil)
                        {
                            [tableView beginUpdates];
                            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                            [tableView endUpdates];
                        }
                    }
                    else
                    {
                        [self updateHeight];
                    }
                });
            }
            else if (mediaItem.view != nil && [mediaItem.view isKindOfClass:[SCRMediaCollectionViewDownloadView class]])
            {
                [[(SCRMediaCollectionViewDownloadView *)mediaItem.view downloadButton] setHidden:NO];
                [[(SCRMediaCollectionViewDownloadView *)mediaItem.view activityView] setHidden:YES];
            }

        }];
    }];
}

- (UITableViewCell *)cellThisViewIsContainedIn
{
    id view = [self superview];
    while (view && [view isKindOfClass:[UITableViewCell class]] == NO) {
        view = [view superview];
    }
    return view;
}

- (UITableView *)tableViewForCell:(UITableViewCell *)cell
{
    if (cell == nil)
        return nil;
    id view = [cell superview];
    while (view && [view isKindOfClass:[UITableView class]] == NO) {
        view = [view superview];
    }
    return view;
}

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    __block int count = 0;
    @synchronized(self.mediaItems)
    {
        [self.mediaItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            SCRMediaCollectionViewItem *mediaItem = obj;
            if (mediaItem.view != nil)
                count++;
        }];
    }
    [self.pageControl setNumberOfPages:count];
    return count;
}

-(void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView
{
    [self.pageControl setCurrentPage:[swipeView currentItemIndex]];
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    __block UIView *imageView = nil;
    __block int count = 0;
    @synchronized(self.mediaItems)
    {
        [self.mediaItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            SCRMediaCollectionViewItem *mediaItem = obj;
            if (mediaItem.view != nil)
            {
                if (count == index)
                {
                    imageView = mediaItem.view;
                    *stop = YES;
                }
                count++;
            }
        }];
    }
    return imageView;
}

- (void)downloadButtonClicked:(SCRMediaCollectionViewDownloadView *)view
{
    @synchronized(self.mediaItems)
    {
        [self.mediaItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            SCRMediaCollectionViewItem *mediaItem = obj;
            if (mediaItem.view == view && !mediaItem.downloaded && !mediaItem.downloading)
            {
                if ([mediaItem.view isKindOfClass:[SCRMediaCollectionViewDownloadView class]])
                {
                    [[(SCRMediaCollectionViewDownloadView *)mediaItem.view downloadButton] setHidden:YES];
                    [[(SCRMediaCollectionViewDownloadView *)mediaItem.view activityView] setHidden:NO];
                }
                *stop = YES;
                [self mediaItemDownload:mediaItem];
            }
        }];
    }
}

@end
