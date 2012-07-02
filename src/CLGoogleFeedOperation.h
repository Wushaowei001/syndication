//
//  CLGoogleFeedOperation.h
//  Syndication
//
//  Created by Calvin Lough on 4/6/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLGoogleFeedOperationDelegate.h"
#import "CLGoogleOperation.h"

@class CLSourceListFeed;

@interface CLGoogleFeedOperation : CLGoogleOperation {
	CLSourceListFeed *feed;
	NSInteger dbNewestItemTimestamp;
	NSInteger expectedNumberOfUnreadItems;
	NSMutableSet *_guidsAlreadyProcessed;
}

@property (retain) CLSourceListFeed *feed;
@property (assign) NSInteger dbNewestItemTimestamp;
@property (assign) NSInteger expectedNumberOfUnreadItems;
@property (retain) NSMutableSet *_guidsAlreadyProcessed;

- (id <CLGoogleFeedOperationDelegate>)delegate;
- (void)setDelegate:(id <CLGoogleFeedOperationDelegate>)delegate;

- (void)updateMetaDataUsingDictionary:(NSDictionary *)dictionary;
- (NSInteger)processItems:(NSArray *)items newPosts:(NSMutableArray *)newPosts dbUnreadGuids:(NSMutableSet *)dbUnreadGuids newestTimestamp:(NSInteger *)newestTimestamp;
- (NSInteger)processUnreadItems:(NSArray *)items unreadGuids:(NSMutableSet *)unreadGuids;
- (void)updateDBWithNewestItemTimestamp:(NSInteger)timestamp;

- (void)dispatchPostReadDelegateMessage:(NSNumber *)dbId;
- (void)dispatchPostUnreadDelegateMessage:(NSNumber *)dbId;
- (void)dispatchWebsiteLinkDelegateMessage;
- (void)dispatchTitleDelegateMessage;
- (void)dispatchNewPostsDelegateMessage:(NSArray *)newPosts;

@end
