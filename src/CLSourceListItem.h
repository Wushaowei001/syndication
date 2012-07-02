//
//  CLSourceListItem.h
//  Syndication
//
//  Created by Calvin Lough on 2/20/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@interface CLSourceListItem : NSObject {
	NSString *title;
	NSMutableArray *children;
	BOOL isGroupItem;
	BOOL isEditable;
	BOOL isDraggable;
	NSInteger badgeValue;
	NSImage *icon;
	NSDate *iconLastRefreshed;
	BOOL isLoading;
}

@property (copy) NSString *title;
@property (retain, nonatomic) NSMutableArray *children;
@property (assign, nonatomic) BOOL isGroupItem;
@property (assign, nonatomic) BOOL isEditable;
@property (assign, nonatomic) BOOL isDraggable;
@property (assign, nonatomic) NSInteger badgeValue;
@property (copy) NSImage *icon;
@property (retain) NSDate *iconLastRefreshed;
@property (assign, nonatomic) BOOL isLoading;

- (NSComparisonResult)localizedCaseInsensitiveCompare:(CLSourceListItem *)aSubscription;
- (NSString *)extractTitleForDisplay;

@end
