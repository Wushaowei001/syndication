//
//  CLSourceListFeed.h
//  Syndication
//
//  Created by Calvin Lough on 01/08/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLSourceListItem.h"

@class CLSourceListFolder;
@class CLWindowController;
@class FMResultSet;

@interface CLSourceListFeed : CLSourceListItem {
	NSInteger dbId;
	NSString *url;
	CLSourceListFolder *enclosingFolderReference;
	BOOL isFromGoogle;
	NSString *googleUrl;
	NSString *websiteLink;
	NSArray *postsToAddToDB;
	NSMutableArray *lastSyncPosts;
	NSMutableSet *googleUnreadGuids;
}

@property (assign, nonatomic) NSInteger dbId;
@property (copy, nonatomic) NSString *url;
@property (assign, nonatomic) CLSourceListFolder *enclosingFolderReference;
@property (assign, nonatomic) BOOL isFromGoogle;
@property (copy, nonatomic) NSString *googleUrl;
@property (copy, nonatomic) NSString *websiteLink;
@property (retain, nonatomic) NSArray *postsToAddToDB;
@property (retain, nonatomic) NSMutableArray *lastSyncPosts;
@property (retain, nonatomic) NSMutableSet *googleUnreadGuids;

- (id)initWithResultSet:(FMResultSet *)rs;
- (void)populateUsingResultSet:(FMResultSet *)rs;

@end
