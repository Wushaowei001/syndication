//
//  CLTimelineView.m
//  Syndication
//
//  Created by Calvin Lough on 02/08/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLTabView.h"
#import "CLTabViewItem.h"
#import "CLTimelineView.h"
#import "CLTimelineViewItem.h"
#import "CLWebView.h"
#import "CLWindowController.h"
#import "SyndicationAppDelegate.h"
#import "NSScrollView+CLAdditions.h"

@interface CLTimelineView (Private)

- (void)removePostAtIndex:(NSInteger)theIndex;

@end

@implementation CLTimelineView

@synthesize scrollViewReference;
@synthesize tabViewItemReference;
@synthesize timelineViewItems;
@synthesize selectedItem;
@synthesize postsMissingFromTopCount;
@synthesize postsMissingFromBottom;
@synthesize lastKnownWidth;
@synthesize informationWebView;
@synthesize shouldIgnoreScrollEvent;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
	if (self != nil) {
		[self setTimelineViewItems:[NSMutableArray array]];
		[self setPostsMissingFromTopCount:0];
		[self setPostsMissingFromBottom:YES];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
	CGFloat currentWidth = [self frame].size.width;
	
	if (currentWidth != lastKnownWidth) {
		if ([self inLiveResize] == NO) {
			
			for (CLTimelineViewItem *timelineViewItem in timelineViewItems) {
				[timelineViewItem updateHeight];
			}
			
			[self updateSubviewRects];
		}
	}
	
	[self setLastKnownWidth:currentWidth];
}

- (void)dealloc {
	
	// zero the weak references
	for (CLTimelineViewItem *timelineViewItem in timelineViewItems) {
		[timelineViewItem setTimelineViewReference:nil];
	}
	
	[timelineViewItems release];
	[selectedItem release];
	[informationWebView release];
	
	[super dealloc];
}

- (BOOL)isFlipped {
	return YES;
}

- (void)updateSubviewRects {
	CGFloat scrollX = [scrollViewReference documentVisibleRect].origin.x;
	CGFloat oldScrollY = [scrollViewReference documentVisibleRect].origin.y;
	CGFloat scrollY = oldScrollY;
	
	CGFloat width = NSWidth([self frame]);
	CGFloat totalHeight = 0.0;
	
	for (CLTimelineViewItem *timelineViewItem in timelineViewItems) {
		totalHeight += [timelineViewItem height];
	}
	
	totalHeight += TIMELINE_FIRST_ITEM_MARGIN_TOP;
	totalHeight += TIMELINE_LAST_ITEM_MARGIN_BOTTOM;
	
	NSRect newFrame = NSMakeRect(0, 0, width, totalHeight);
	[self setFrame:newFrame];
	
	CGFloat oldHeight = 0.0;
	CGFloat height = 0.0;
	CGFloat currentOffset = TIMELINE_FIRST_ITEM_MARGIN_TOP;
	NSRect currentRect;
	NSUInteger i = 0;
	
	for (CLTimelineViewItem *timelineViewItem in timelineViewItems) {
		oldHeight = [timelineViewItem heightAtLastUpdate];
		height = [timelineViewItem height];
		
		if (i == ([timelineViewItems count] - 1)) {
			height += TIMELINE_LAST_ITEM_MARGIN_BOTTOM;
		}
		
		currentRect = NSMakeRect(0.0, currentOffset, width, height);
		[[timelineViewItem view] setFrame:currentRect];
		[[timelineViewItem view] setNeedsDisplay:YES];
		
		// if this item changed size and is before the scroll position, we need to update the scroll position
		CGFloat heightChange = 0.0;
		
		if ([timelineViewItem isNewPost] == NO) {
			if (currentOffset < scrollY) {
				heightChange = (height - oldHeight);
			}
		} else {
			if ((currentOffset - TIMELINE_ITEM_BUFFER) < scrollY) {
				heightChange = height;
			}
		}
		
		[timelineViewItem setHeightAtLastUpdate:height];
		[timelineViewItem setIsNewPost:NO];
		
		scrollY += heightChange;
		
		currentOffset += height;
		
		i++;
	}
	
	if (oldScrollY != scrollY) {
		[self setShouldIgnoreScrollEvent:YES];
		
		[scrollViewReference clScrollInstantlyTo:NSMakePoint(scrollX, scrollY)];
	}
}

- (void)removeAllPostsFromTimeline {
	
	if ([timelineViewItems count] > 0) {
		[self removePostsInRange:NSMakeRange(0, [timelineViewItems count]) preserveScrollPosition:NO updateMetadata:NO];
	}
	
	[self setPostsMissingFromTopCount:0];
	[self setPostsMissingFromBottom:YES];
	
	[scrollViewReference clScrollToTop];
}

- (void)removePostsInRange:(NSRange)range preserveScrollPosition:(BOOL)preserveScroll updateMetadata:(BOOL)updateMetadata {
	
	if (range.length == 0) {
		return;
	}
	
	if ((range.location + range.length) > [timelineViewItems count]) {
		return;
	}
	
	CLSourceListItem *sourceListItem = [tabViewItemReference sourceListItem];
	BOOL isOnlyUnreadItems = (sourceListItem == [[[self window] windowController] sourceListNewItems]);
	NSInteger postsRemovedCount = 0;
	CGFloat scrollX = [scrollViewReference documentVisibleRect].origin.x;
	CGFloat oldScrollY = [scrollViewReference documentVisibleRect].origin.y;
	CGFloat scrollY = oldScrollY;
	CGFloat firstItemOffset = [[[timelineViewItems objectAtIndex:range.location] view] frame].origin.y;
	
	for (NSInteger i=(range.location + range.length - 1); i>=(NSInteger)range.location; i--) {
		CLTimelineViewItem *timelineViewItem = [timelineViewItems objectAtIndex:i];
		
		if (isOnlyUnreadItems) {
			if ([timelineViewItem isRead] == NO) {
				postsRemovedCount++;
			}
		} else {
			postsRemovedCount++;
		}
		
		CGFloat currentItemHeight = [[timelineViewItem view] frame].size.height;
		
		// if isNewPost == YES, then this post is brand new, so we don't need to account for it
		if ([timelineViewItem isNewPost] == NO) {
			if (firstItemOffset < scrollY) {
				scrollY -= currentItemHeight;
				
				if (scrollY < 0) {
					scrollY = 0;
				}
			}
		}
		
		[self removePostAtIndex:i];
	}
	
	if (preserveScroll && oldScrollY != scrollY) {
		[self setShouldIgnoreScrollEvent:YES];
		
		[scrollViewReference clScrollInstantlyTo:NSMakePoint(scrollX, scrollY)];
	}
	
	if (updateMetadata) {
		if (range.location == 0) {
			[self setPostsMissingFromTopCount:(postsMissingFromTopCount + postsRemovedCount)];
		} else if (postsRemovedCount > 0) {
			[self setPostsMissingFromBottom:YES];
		}
		
		if ([timelineViewItems count] == 0) {
			[self setPostsMissingFromTopCount:0];
			[self setPostsMissingFromBottom:YES];
		}
	}
}

- (void)removePostAtIndex:(NSInteger)theIndex {
	CLTimelineViewItem *timelineViewItem = [timelineViewItems objectAtIndex:theIndex];
	
	[timelineViewItem setTimelineViewReference:nil];
	
	CLWebView *webView = [timelineViewItem webView];
	[webView stopLoading:self];
	[webView setTabViewItemReference:nil];
	[webView setPolicyDelegate:nil];
	[webView setFrameLoadDelegate:nil];
	[webView setUIDelegate:nil];
	
	[[timelineViewItem view] removeFromSuperview];
	
	WebScriptObject *windowObject = [[timelineViewItem webView] windowScriptObject];
	[windowObject setValue:nil forKey:@"webScriptHelper"];
	
	if ([timelineViewItem heightUpdateTimer] != nil) {
		if ([[timelineViewItem heightUpdateTimer] isValid]) {
			[[timelineViewItem heightUpdateTimer] invalidate];
		}
		[timelineViewItem setHeightUpdateTimer:nil];
	}
	
	if ([timelineViewItem isRead] == NO) {
		[SyndicationAppDelegate removeFromTimelineUnreadItemsDict:timelineViewItem];
	}
	
	if (timelineViewItem == selectedItem) {
		[self setSelectedItem:nil];
	}
	
	[timelineViewItems removeObjectAtIndex:theIndex];
}

@end
