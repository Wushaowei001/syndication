//
//  CLGoogleFeedOperationDelegate.h
//  Syndication
//
//  Created by Calvin Lough on 4/6/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLGoogleOperationDelegate.h"

@class CLGoogleFeedOperation;
@class CLSourceListFeed;

@protocol CLGoogleFeedOperationDelegate <CLGoogleOperationDelegate>

- (void)googleFeedOperation:(CLGoogleFeedOperation *)feedOp markPostWithDbIdAsRead:(NSInteger)dbId;
- (void)googleFeedOperation:(CLGoogleFeedOperation *)feedOp markPostWithDbIdAsUnread:(NSInteger)dbId;
- (void)googleFeedOperation:(CLGoogleFeedOperation *)feedOp foundWebsiteLinkForFeed:(CLSourceListFeed *)feed;
- (void)googleFeedOperation:(CLGoogleFeedOperation *)feedOp foundTitleForFeed:(CLSourceListFeed *)feed;
- (void)googleFeedOperation:(CLGoogleFeedOperation *)feedOp foundNewPosts:(NSArray *)newPosts forFeed:(CLSourceListFeed *)feed;

@end
