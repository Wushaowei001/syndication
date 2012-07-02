//
//  NSScrollView+CLAdditions.m
//  Syndication
//
//  Created by Calvin Lough on 3/7/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "NSScrollView+CLAdditions.h"

#define SCROLL_ARROW_INCREMENT 40

@implementation NSScrollView (CLAdditions)

- (void)ayScrollToTop {
	[self ayScrollInstantlyTo:NSMakePoint(0.0, 0.0)];
}

- (void)ayScrollToBottom {
	CGFloat documentHeight = [[self contentView] documentRect].size.height;
	CGFloat clipViewHeight = [[self contentView] frame].size.height;
	
	[self ayScrollInstantlyTo:NSMakePoint(0.0, documentHeight - clipViewHeight)];
}

- (void)ayPageUp {
	NSRect documentVisibleRect = [[self contentView] documentVisibleRect];
	CGFloat originalScrollX = documentVisibleRect.origin.x;
	CGFloat originalScrollY = documentVisibleRect.origin.y;
	CGFloat pageSize = [[self contentView] frame].size.height;
	
	// not sure what the "official" way is to do this (to scroll slightly less than a page each time)
	if (pageSize > 400) {
		pageSize -= 35;
	}
	
	[self ayScrollTo:NSMakePoint(originalScrollX, originalScrollY - pageSize)];
}

- (void)ayPageDown {
	NSRect documentVisibleRect = [[self contentView] documentVisibleRect];
	CGFloat originalScrollX = documentVisibleRect.origin.x;
	CGFloat originalScrollY = documentVisibleRect.origin.y;
	CGFloat pageSize = [[self contentView] frame].size.height;
	
	// not sure what the "official" way is to do this (to scroll slightly less than a page each time)
	if (pageSize > 400) {
		pageSize -= 35;
	}
	
	[self ayScrollTo:NSMakePoint(originalScrollX, originalScrollY + pageSize)];
}

- (void)ayScrollTo:(NSPoint)scrollPoint {
	NSClipView *clipView = [self contentView];
	scrollPoint = [clipView constrainScrollPoint:scrollPoint];
	[clipView scrollToPoint:scrollPoint];
	[self reflectScrolledClipView:clipView];
}

- (void)ayScrollInstantlyTo:(NSPoint)scrollPoint {
	NSClipView *clipView = [self contentView];
	scrollPoint = [clipView constrainScrollPoint:scrollPoint];
	[clipView setBoundsOrigin:scrollPoint];
	[self reflectScrolledClipView:clipView];
}

@end
