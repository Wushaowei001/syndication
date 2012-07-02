//
//  CLGoogleSyncOperation.h
//  Syndication
//
//  Created by Calvin Lough on 3/29/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLGoogleOperation.h"
#import "CLGoogleSyncOperationDelegate.h"

@class CLSourceListFeed;

@interface CLGoogleSyncOperation : CLGoogleOperation {
	
}

- (id <CLGoogleSyncOperationDelegate>)delegate;
- (void)setDelegate:(id <CLGoogleSyncOperationDelegate>)delegate;

- (void)dbPopulateFeedList:(NSMutableArray **)feedListPtr titleDictionary:(NSMutableDictionary **)titleDictPtr newestItemDictionary:(NSMutableDictionary **)newestItemDictPtr;
- (void)dispatchDeleteFeedDelegateMessage:(NSString *)urlString;
- (void)dispatchAddFeedDelegateMessage:(NSDictionary *)params;
- (void)dispatchFoundTitleDelegateMessage:(NSDictionary *)params;
- (void)dispatchFoundFolderDelegateMessage:(NSDictionary *)params;
- (void)dispatchQueueFeedDelegateMessage:(NSDictionary *)params;

@end
