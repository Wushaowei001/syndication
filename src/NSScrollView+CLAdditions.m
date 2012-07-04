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

- (void)clScrollToTop {
	[self clScrollInstantlyTo:NSMakePoint(0.0, 0.0)];
}

- (void)clScrollToBottom {
	CGFloat documentHeight = [[self contentView] documentRect].size.height;
	CGFloat clipViewHeight = [[self contentView] frame].size.height;
	
	[self clScrollInstantlyTo:NSMakePoint(0.0, documentHeight - clipViewHeight)];
}

- (void)clPageUp {
	NSRect documentVisibleRect = [[self contentView] documentVisibleRect];
	CGFloat originalScrollX = documentVisibleRect.origin.x;
	CGFloat originalScrollY = documentVisibleRect.origin.y;
	CGFloat pageSize = [[self contentView] frame].size.height;
	
	// not sure what the "official" way is to do this (to scroll slightly less than a page each time)
	if (pageSize > 400) {
		pageSize -= 35;
	}
	
	[self clScrollTo:NSMakePoint(originalScrollX, originalScrollY - pageSize)];
}

- (void)clPageDown {
	NSRect documentVisibleRect = [[self contentView] documentVisibleRect];
	CGFloat originalScrollX = documentVisibleRect.origin.x;
	CGFloat originalScrollY = documentVisibleRect.origin.y;
	CGFloat pageSize = [[self contentView] frame].size.height;
	
	// not sure what the "official" way is to do this (to scroll slightly less than a page each time)
	if (pageSize > 400) {
		pageSize -= 35;
	}
	
	[self clScrollTo:NSMakePoint(originalScrollX, originalScrollY + pageSize)];
}

- (void)clScrollTo:(NSPoint)scrollPoint {
	NSClipView *clipView = [self contentView];
	scrollPoint = [clipView constrainScrollPoint:scrollPoint];
	[clipView scrollToPoint:scrollPoint];
	[self reflectScrolledClipView:clipView];
}

- (void)clScrollInstantlyTo:(NSPoint)scrollPoint {
	NSClipView *clipView = [self contentView];
	scrollPoint = [clipView constrainScrollPoint:scrollPoint];
	[clipView setBoundsOrigin:scrollPoint];
	[self reflectScrolledClipView:clipView];
}

@end
