//
//  CLFeedParserDelegate.h
//  Syndication
//
//  Created by Calvin Lough on 6/23/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLOperationDelegate.h"

@class CLSourceListFeed;

@protocol CLFeedParserOperationDelegate <CLOperationDelegate>

- (void)feedParserOperationFoundNewPostsForFeed:(CLSourceListFeed *)feed;
- (void)feedParserOperationFoundTitleForFeed:(CLSourceListFeed *)feed;
- (void)feedParserOperationFoundWebsiteLinkForFeed:(CLSourceListFeed *)feed;

@end
