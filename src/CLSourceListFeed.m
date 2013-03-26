//
//  CLSourceListFeed.m
//  Syndication
//
//  Created by Calvin Lough on 01/08/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLSourceListFeed.h"
#import "FMResultSet.h"

@implementation CLSourceListFeed

@synthesize dbId;
@synthesize url;
@synthesize enclosingFolderReference;
@synthesize websiteLink;
@synthesize postsToAddToDB;
@synthesize lastSyncPosts;

- (id)init {
	self = [super init];
	
	if (self != nil) {
		[self setIsEditable:YES];
		[self setIsDraggable:YES];
	}
	
	return self;
}

- (id)initWithResultSet:(FMResultSet *)rs {
	self = [self init];
	
	if (self != nil) {
		[self populateUsingResultSet:rs];
	}
	
	return self;
}

- (void)populateUsingResultSet:(FMResultSet *)rs {
	[self setDbId:[rs longForColumn:@"Id"]];
	[self setUrl:[rs stringForColumn:@"Url"]];
	[self setTitle:[rs stringForColumn:@"Title"]];
	
	NSData *iconData = [rs dataForColumn:@"Icon"];
	
	if (iconData != nil) {
		[self setIcon:[NSUnarchiver unarchiveObjectWithData:iconData]];
	}
	
	[self setBadgeValue:[rs longForColumn:@"UnreadCount"]];
	[self setIconLastRefreshed:[rs dateForColumn:@"IconLastRefreshed"]];
	[self setWebsiteLink:[rs stringForColumn:@"WebsiteLink"]];
	
	NSData *lastSyncPostsData = [rs dataForColumn:@"LastSyncPosts"];
	
	if (lastSyncPostsData != nil) {
		[self setLastSyncPosts:[NSUnarchiver unarchiveObjectWithData:lastSyncPostsData]];
	}
}

- (void)dealloc {
	[url release];
	[websiteLink release];
	[postsToAddToDB release];
	[lastSyncPosts release];
	
	[super dealloc];
}

@end
