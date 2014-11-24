//
//  SRCFeedFetcher.m
//  SecureReader
//
//  Created by Christopher Ballinger on 11/17/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRFeedFetcher.h"
#import "RSSAtomKit.h"
#import "SCRDatabaseManager.h"
#import "SCRItem.h"
#import "SCRFeed.h"

@interface SCRFeedFetcher()
@property (nonatomic, strong, readonly) RSSAtomKit *atomKit;
@property (nonatomic, strong, readonly) dispatch_queue_t callbackQueue;
@end

@implementation SCRFeedFetcher

- (instancetype) init {
    if (self = [super init]) {
        _atomKit = [[RSSAtomKit alloc] initWithSessionConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
        _callbackQueue = dispatch_queue_create("SCRFeedFetcher callback queue", 0);
        [self.atomKit.parser registerFeedClass:[SCRFeed class]];
        [self.atomKit.parser registerItemClass:[SCRItem class]];
    }
    return self;
}

/**
 *  Fetches RSS feed info and items and inserts it into the database.
 *
 *  @param url rss feed url
 */
- (void) fetchFeedDataFromURL:(NSURL*)url {
    [self.atomKit parseFeedFromURL:url completionBlock:^(RSSFeed *feed, NSArray *items, NSError *error) {
        NSLog(@"Parsed feed %@ with %lu items", feed.title, (unsigned long)items.count);
        if ([feed isKindOfClass:[SCRFeed class]]) {
            SCRFeed *nativeFeed = (SCRFeed*)feed;
            [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [transaction setObject:nativeFeed forKey:nativeFeed.yapKey inCollection:[[nativeFeed class] yapCollection]];
                [items enumerateObjectsUsingBlock:^(RSSItem *item, NSUInteger idx, BOOL *stop) {
                    if ([item isKindOfClass:[SCRItem class]]) {
                        SCRItem *nativeItem = (SCRItem*)item;
                        NSLog(@"Parsed feed %@ item: %@", feed.title, item.title);
                        [transaction setObject:nativeItem forKey:nativeItem.yapKey inCollection:[[nativeItem class] yapCollection]];
                    }
                }];
            }];
        }
    } completionQueue:self.callbackQueue];
}


@end