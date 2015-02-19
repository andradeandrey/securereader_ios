//
//  SCRFeedFetcher.h
//  SecureReader
//
//  Created by Christopher Ballinger on 11/17/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCRFeedFetcher : NSObject

/**
 *  Fetches RSS feed info and items and inserts it into the database.
 *
 *  @param url rss feed url
 */
- (void) fetchFeedDataFromURL:(NSURL*)url;


/**
 *  Wraps RSSAtomKit to use network and class defaults
 *
 *  @param url OPML document url
 *  @param completionBlock The result with an array of SCRFeed(s)
 *  @param completionQuee The queue to callback on if nil uses main queue
 *
 */

- (void) fetchFeedsFromOPMLURL:(NSURL *)url
               completionBlock:(void (^)(NSArray *feeds, NSError *error))completionBlock
               completionQueue:(dispatch_queue_t)completionQueue;

@end
