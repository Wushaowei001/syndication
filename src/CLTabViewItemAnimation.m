//
//  CLTabViewItemAnimation.m
//  Syndication
//
//  Created by Calvin Lough on 01/22/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLTabViewItemAnimation.h"
#import "CLTabViewItem.h"

@implementation CLTabViewItemAnimation

@synthesize tabViewItemReference;
@synthesize originalXPosition;
@synthesize targetXPosition;

- (id)init {
	self = [super init];
	if (self != nil) {
		[self setAnimationBlockingMode:NSAnimationNonblocking];
		[self setFrameRate:40];
		[self setAnimationCurve:NSAnimationEaseIn];
		[self setDuration:0.2];
	}
	return self;
}

- (void)setCurrentProgress:(NSAnimationProgress)progress {
	[super setCurrentProgress:progress];
	
	NSInteger newXPosition = originalXPosition + ((double)progress * (targetXPosition - originalXPosition));
	NSRect oldRect = [tabViewItemReference rect];
	NSRect newRect = NSMakeRect(newXPosition, oldRect.origin.y, oldRect.size.width, oldRect.size.height);
	[tabViewItemReference setRect:newRect];
	[tabViewItemReference setTabCloseRect:NSMakeRect(newRect.origin.x + TAB_CLOSE_X_INDENT, newRect.origin.y + TAB_CLOSE_Y_INDENT, TAB_CLOSE_WIDTH, TAB_CLOSE_HEIGHT)];
	
	[[tabViewItemReference tabViewReference] display];
}

@end
