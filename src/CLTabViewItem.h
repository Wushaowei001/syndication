//
//  CLTabViewItem.h
//  Syndication
//
//  Created by Calvin Lough on 01/14/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@class CLClassicView;
@class CLSourceListItem;
@class CLTabView;
@class CLTabViewItemAnimation;
@class CLTimelineView;
@class CLWebTab;

typedef enum {CLTimelineType, CLClassicType, CLWebType} CLTabViewItemType;

@interface CLTabViewItem : NSObject <NSAnimationDelegate> {
	CLTabView *tabViewReference;
	CLTabViewItemType tabType;
	CLSourceListItem *sourceListItem;
	NSString *searchQuery;
	NSString *searchFieldValue;
	BOOL isSelected;
	BOOL isHover;
	BOOL isCloseButtonHover;
	BOOL isSliding;
	BOOL isLoading;
	NSView *linkedView;
	CLTimelineView *timelineView;
	CLWebTab *webTab;
	CLClassicView *classicView;
	NSString *label;
	NSRect rect;
	NSRect tabCloseRect;
	NSTrackingRectTag trackingTag;
	NSTrackingRectTag closeButtonTrackingTag;
	CLTabViewItemAnimation *slideAnimation;
	NSProgressIndicator *spinner;
}

@property (assign, nonatomic) CLTabView *tabViewReference; // weak reference
@property (assign, nonatomic) CLTabViewItemType tabType;
@property (assign, nonatomic) CLSourceListItem *sourceListItem;
@property (copy, nonatomic) NSString *searchQuery;
@property (copy, nonatomic) NSString *searchFieldValue;
@property (assign, nonatomic) BOOL isSelected;
@property (assign, nonatomic) BOOL isHover;
@property (assign, nonatomic) BOOL isCloseButtonHover;
@property (assign, nonatomic) BOOL isSliding;
@property (assign, nonatomic) BOOL isLoading;
@property (retain, nonatomic) NSView *linkedView;
@property (retain, nonatomic) CLTimelineView *timelineView;
@property (retain, nonatomic) CLWebTab *webTab;
@property (retain, nonatomic) CLClassicView *classicView;
@property (copy, nonatomic) NSString *label;
@property (assign, nonatomic) NSRect rect;
@property (assign, nonatomic) NSRect tabCloseRect;
@property (assign, nonatomic) NSTrackingRectTag trackingTag;
@property (assign, nonatomic) NSTrackingRectTag closeButtonTrackingTag;
@property (retain, nonatomic) CLTabViewItemAnimation *slideAnimation;
@property (retain, nonatomic) NSProgressIndicator *spinner;

- (void)slideToXPosition:(NSInteger)xPos animate:(BOOL)flag;

- (void)updateTrackingRects;
- (void)draw;

@end
