//
//  CLSourceListItem.m
//  Syndication
//
//  Created by Calvin Lough on 2/20/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLSourceListItem.h"
#import "CLSourceListFeed.h"

@implementation CLSourceListItem

@synthesize title;
@synthesize children;
@synthesize isGroupItem;
@synthesize isEditable;
@synthesize isDraggable;
@synthesize badgeValue;
@synthesize icon;
@synthesize iconLastRefreshed;
@synthesize isLoading;

- (id)init {
	self = [super init];
	if (self != nil) {
		[self setChildren:[NSMutableArray array]];
		[self setIsGroupItem:NO];
		[self setIsEditable:NO];
		[self setIsDraggable:NO];
		[self setBadgeValue:0];
		[self setIsLoading:NO];
	}
	return self;
}

- (void)dealloc {
	[title release];
	[children release];
	[icon release];
	[iconLastRefreshed release];
	
	[super dealloc];
}

- (NSComparisonResult)localizedCaseInsensitiveCompare:(CLSourceListItem *)sourceListItem {
	return [title localizedCaseInsensitiveCompare:[sourceListItem title]];
}

// extract some form of a title from this item for use in source list, etc
- (NSString *)extractTitleForDisplay {
	NSString *builtTitle = @"";
	
	if ([self title] != nil && [[self title] length] > 0) {
		builtTitle = [self title];
	} else if ([self isKindOfClass:[CLSourceListFeed class]]) {
		if ([(CLSourceListFeed *)self url] != nil && [[(CLSourceListFeed *)self url] length] > 0) {
			builtTitle = [(CLSourceListFeed *)self url];
		}
	}
	
	return builtTitle;
}

@end
