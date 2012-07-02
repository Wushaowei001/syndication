//
//  CLGoogleSyncOperationDelegate.h
//  Syndication
//
//  Created by Calvin Lough on 3/29/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLGoogleOperationDelegate.h"

@class CLGoogleSyncOperation;
@class CLSourceListFeed;

@protocol CLGoogleSyncOperationDelegate <CLGoogleOperationDelegate>

- (void)googleSyncOperation:(CLGoogleSyncOperation *)syncOp deleteFeedWithUrlString:(NSString *)urlString;
- (void)googleSyncOperation:(CLGoogleSyncOperation *)syncOp addFeedWithUrlString:(NSString *)urlString title:(NSString *)title folderTitle:(NSString *)folderTitle;
- (void)googleSyncOperation:(CLGoogleSyncOperation *)syncOp foundTitle:(NSString *)title forUrlString:(NSString *)urlString;
- (void)googleSyncOperation:(CLGoogleSyncOperation *)syncOp foundFolder:(NSString *)folder forUrlString:(NSString *)urlString;
- (void)googleSyncOperation:(CLGoogleSyncOperation *)syncOp queueFeedOperationForUrlString:(NSString *)urlString newestItemTimestamp:(NSInteger)timestamp unreadCount:(NSInteger)unreadCount;

@end
