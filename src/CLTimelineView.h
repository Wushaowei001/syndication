//
//  CLTimelineView.h
//  Syndication
//
//  Created by Calvin Lough on 02/08/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import <WebKit/WebKit.h>

@class CLTabViewItem;
@class CLTimelineViewItem;

@interface CLTimelineView : NSView {
	NSScrollView *scrollViewReference;
	CLTabViewItem *tabViewItemReference;
	NSMutableArray *timelineViewItems;
	CLTimelineViewItem *selectedItem;
	NSInteger postsMissingFromTopCount;
	BOOL postsMissingFromBottom;
	CGFloat lastKnownWidth;
	WebView *informationWebView;
	BOOL shouldIgnoreScrollEvent;
}

@property (assign, nonatomic) NSScrollView *scrollViewReference; // weak reference
@property (assign, nonatomic) CLTabViewItem *tabViewItemReference; // weak reference
@property (retain, nonatomic) NSMutableArray *timelineViewItems;
@property (retain, nonatomic) CLTimelineViewItem *selectedItem;
@property (assign, nonatomic) NSInteger postsMissingFromTopCount;
@property (assign, nonatomic) BOOL postsMissingFromBottom;
@property (assign, nonatomic) CGFloat lastKnownWidth;
@property (retain, nonatomic) WebView *informationWebView;
@property (assign, nonatomic) BOOL shouldIgnoreScrollEvent; // set this to true before triggering a scroll event in code

- (void)updateSubviewRects;
- (void)removeAllPostsFromTimeline;
- (void)removePostsInRange:(NSRange)range preserveScrollPosition:(BOOL)preserveScroll updateMetadata:(BOOL)updateMetadata;

@end
