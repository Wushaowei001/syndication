//
//  CLGoogleStarredOperationDelegate.h
//  Syndication
//
//  Created by Calvin Lough on 6/14/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@class CLGoogleStarredOperation;
@class CLSourceListFeed;

@protocol CLGoogleStarredOperationDelegate <CLGoogleOperationDelegate>

- (void)googleStarredOperation:(CLGoogleStarredOperation *)starredOperation addStarredItems:(NSArray *)items;
- (void)googleStarredOperation:(CLGoogleStarredOperation *)starredOperation removeStarredItems:(NSArray *)items;
- (void)googleStarredOperation:(CLGoogleStarredOperation *)starredOperation didAddNewHiddenFeed:(CLSourceListFeed *)feed;

@end
