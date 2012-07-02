//
//  CLGoogleStarredOperation.h
//  Syndication
//
//  Created by Calvin Lough on 6/14/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLGoogleOperation.h"
#import "CLGoogleStarredOperationDelegate.h"

@class CLSourceListFeed;

@interface CLGoogleStarredOperation : CLGoogleOperation {
	
}

- (id <CLGoogleStarredOperationDelegate>)delegate;
- (void)setDelegate:(id <CLGoogleStarredOperationDelegate>)delegate;

- (NSArray *)getDbStarredItems;

- (void)dispatchAddItemsDelegateMessage:(NSArray *)items;
- (void)dispatchRemoveItemsDelegateMessage:(NSArray *)items;
- (void)dispatchDidAddHiddenFeedDelegateMessage:(CLSourceListFeed *)feed;

@end
