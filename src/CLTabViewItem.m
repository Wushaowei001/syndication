//
//  CLTabViewItem.m
//  Syndication
//
//  Created by Calvin Lough on 01/14/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLClassicView.h"
#import "CLConstants.h"
#import "CLDatabaseHelper.h"
#import "CLTabViewItem.h"
#import "CLTabViewItemAnimation.h"
#import "CLTimelineView.h"
#import "CLPost.h"
#import "CLWebTab.h"
#import "CLWebView.h"
#import "FMDatabase.h"

#define TEXT_PADDING_LEFT 21
#define TEXT_PADDING_RIGHT 6
#define TEXT_SPINNER_PADDING 17
#define TRACKING_RECT_TAB 1
#define TRACKING_RECT_CLOSE 2

@implementation CLTabViewItem

static NSImage *tabBackSelected;
static NSImage *tabHover;
static NSImage *tabClose;
static NSImage *tabCloseHover;

@synthesize tabViewReference;
@synthesize tabType;
@synthesize sourceListItem;
@synthesize searchQuery;
@synthesize searchFieldValue;
@synthesize isSelected;
@synthesize isHover;
@synthesize isCloseButtonHover;
@synthesize isSliding;
@synthesize isLoading;
@synthesize linkedView;
@synthesize timelineView;
@synthesize webTab;
@synthesize classicView;
@synthesize label;
@synthesize rect;
@synthesize tabCloseRect;
@synthesize trackingTag;
@synthesize closeButtonTrackingTag;
@synthesize slideAnimation;
@synthesize spinner;

+ (void)initialize {
	NSString *tabBackSelectedName = [[NSBundle mainBundle] pathForResource:@"tabBackSelected" ofType:@"png"];
	tabBackSelected = [[NSImage alloc] initWithContentsOfFile:tabBackSelectedName];
	
	NSString *tabHoverName = [[NSBundle mainBundle] pathForResource:@"tabHover" ofType:@"png"];
	tabHover = [[NSImage alloc] initWithContentsOfFile:tabHoverName];
	
	NSString *tabCloseName = [[NSBundle mainBundle] pathForResource:@"tabClose" ofType:@"png"];
	tabClose = [[NSImage alloc] initWithContentsOfFile:tabCloseName];
	
	NSString *tabCloseHoverName = [[NSBundle mainBundle] pathForResource:@"tabCloseHover" ofType:@"png"];
	tabCloseHover = [[NSImage alloc] initWithContentsOfFile:tabCloseHoverName];
}

- (id)init {
	self = [super init];
	if (self != nil) {
		[self setTrackingTag:-1];
		[self setCloseButtonTrackingTag:-1];
		
		NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
		[progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
		[progressIndicator setUsesThreadedAnimation:YES];
		[progressIndicator setHidden:YES];
		
		[self setSpinner:progressIndicator];
		[progressIndicator release];
	}
	return self;
}

- (void)dealloc {
	
	if (trackingTag != -1) {
		[tabViewReference removeTrackingRect:trackingTag];
	}
	
	if (closeButtonTrackingTag != -1) {
		[tabViewReference removeTrackingRect:closeButtonTrackingTag];
	}
	
	if (slideAnimation != nil) {
		if ([slideAnimation isAnimating]) {
			[slideAnimation stopAnimation];
		}
	}
	
	if (tabType == CLTimelineType) {
		if ([[timelineView timelineViewItems] count] > 0) {
			[timelineView removePostsInRange:NSMakeRange(0, [[timelineView timelineViewItems] count]) preserveScrollPosition:NO updateMetadata:NO];
		}
		
		[timelineView setTabViewItemReference:nil];
	} else if (tabType == CLClassicType) {
		[classicView setTabViewItemReference:nil];
	}
	
	[linkedView removeFromSuperview];
	[spinner removeFromSuperview];
	
	// zero weak refs
	if (tabType == CLWebType) {
		[[webTab webView] setTabViewItemReference:nil];
	}
	
	[timelineView setTabViewItemReference:nil];
	[slideAnimation setTabViewItemReference:nil];
	
	[searchQuery release];
	[searchFieldValue release];
	[linkedView release];
	[timelineView release];
	[webTab release];
	[classicView release];
	[label release];
	[slideAnimation release];
	[spinner release];
	
	[super dealloc];
}

- (void)slideToXPosition:(NSInteger)xPos animate:(BOOL)flag {
	
	// if an animation is already in progress, stop it
	if (slideAnimation != nil) {
		if ([slideAnimation isAnimating]) {
			[slideAnimation stopAnimation];
		}
	}
	
	if (flag == NO) {
		[self setRect:NSMakeRect(xPos, rect.origin.y, rect.size.width, rect.size.height)];
		[self setTabCloseRect:NSMakeRect(rect.origin.x + TAB_CLOSE_X_INDENT, rect.origin.y + TAB_CLOSE_Y_INDENT, TAB_CLOSE_WIDTH, TAB_CLOSE_HEIGHT)];
		[self updateTrackingRects];
	} else {
		
		// tracking tags are essentially pointless if this tab is going to be sliding under another tab
		if (trackingTag != -1) {
			[tabViewReference removeTrackingRect:trackingTag];
			[self setTrackingTag:-1];
		}
		
		if (closeButtonTrackingTag != -1) {
			[tabViewReference removeTrackingRect:closeButtonTrackingTag];
			[self setCloseButtonTrackingTag:-1];
		}
		
		if (slideAnimation == nil) {
			slideAnimation = [[CLTabViewItemAnimation alloc] init];
			[slideAnimation setTabViewItemReference:self];
			[slideAnimation setDelegate:self];
		}
		
		[slideAnimation setOriginalXPosition:rect.origin.x];
		[slideAnimation setTargetXPosition:xPos];
		[slideAnimation startAnimation];
		
		[self setIsSliding:YES];
	}
}

- (void)updateTrackingRects {
	
	if (trackingTag != -1) {
		[tabViewReference removeTrackingRect:trackingTag];
		[self setTrackingTag:-1];
	}
	
	NSRect trackingRect = NSMakeRect(rect.origin.x + 1, rect.origin.y, rect.size.width - 2, rect.size.height);
	NSTrackingRectTag trackTag = [tabViewReference addTrackingRect:trackingRect owner:self userData:[NSNumber numberWithInt:TRACKING_RECT_TAB] assumeInside:NO];
	[self setTrackingTag:trackTag];	
	
	if (closeButtonTrackingTag != -1) {
		[tabViewReference removeTrackingRect:closeButtonTrackingTag];
		[self setCloseButtonTrackingTag:-1];
	}
	
	trackTag = [tabViewReference addTrackingRect:tabCloseRect owner:self userData:[NSNumber numberWithInt:TRACKING_RECT_CLOSE] assumeInside:NO];
	[self setCloseButtonTrackingTag:trackTag];
}

- (void)draw {
	
    if (isSelected) {
		[tabBackSelected drawInRect:rect fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	} else if (isHover) {
		[tabHover drawInRect:rect fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	}
	
	if (isCloseButtonHover) {
		[tabCloseHover drawInRect:tabCloseRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	} else {
		[tabClose drawInRect:tabCloseRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	}
	
	// line at left side of tabs
	[[NSColor colorWithCalibratedWhite:(140.0f / 255.0f) alpha:1] set];
	NSRect lineRect = NSMakeRect(rect.origin.x - 1, rect.origin.y, 1, rect.size.height);
	NSRectFill(lineRect);
	
	// line at right side of tabs
	NSRect lineRect2 = NSMakeRect(rect.origin.x + rect.size.width - 1, rect.origin.y, 1, rect.size.height);
	NSRectFill(lineRect2);
	
	NSMutableAttributedString *tabTitle;
	
	if (label != nil) {
		tabTitle = [[NSMutableAttributedString alloc] initWithString:label];
	} else {
		tabTitle = [[NSMutableAttributedString alloc] initWithString:@""];
	}
	
	NSRange range = NSMakeRange(0, [tabTitle length]);
	
	[tabTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11.0] range:range];
	[tabTitle addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithCalibratedWhite:0.1 alpha:1.0] range:range];
	
	NSShadow *textShadow = [[NSShadow alloc] init];
	
	if (isSelected) {
		[textShadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]];
	} else {
		[textShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.96 alpha:1.0]];
	}
	
	[textShadow setShadowOffset:NSMakeSize(0, -1)];
	[textShadow setShadowBlurRadius:1.0];
	[tabTitle addAttribute:NSShadowAttributeName value:textShadow range:range];
	[textShadow release];
	
	NSMutableParagraphStyle *truncateTail = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[truncateTail setLineBreakMode:NSLineBreakByTruncatingTail];
	[truncateTail setAlignment:NSCenterTextAlignment];
    [tabTitle addAttribute:NSParagraphStyleAttributeName value:truncateTail range:range];
	[truncateTail release];
	
	NSRect textRect = NSMakeRect(rect.origin.x + TEXT_PADDING_LEFT, rect.origin.y, rect.size.width - TEXT_PADDING_LEFT - TEXT_PADDING_RIGHT, rect.size.height - 3);
	
	if (isLoading) {
		textRect.size.width -= TEXT_SPINNER_PADDING;
	}
	
	[tabTitle drawInRect:textRect];
	[tabTitle release];
	
	[spinner setFrame:NSMakeRect(rect.origin.x + rect.size.width - 19, rect.origin.y + 4, 14, 14)];
}


#pragma mark Mouse tracking

- (void)mouseEntered:(NSEvent *)theEvent {
	NSInteger trackingRectId = [(NSNumber *)[theEvent userData] integerValue];
	
	if (trackingRectId == TRACKING_RECT_TAB) {
		[self setIsHover:YES];
	} else if (trackingRectId == TRACKING_RECT_CLOSE) {
		[self setIsCloseButtonHover:YES];
	}
	
	[tabViewReference setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent {
	NSInteger trackingRectId = [(NSNumber *)[theEvent userData] integerValue];
	
	if (trackingRectId == TRACKING_RECT_TAB) {
		[self setIsHover:NO];
	} else if (trackingRectId == TRACKING_RECT_CLOSE) {
		[self setIsCloseButtonHover:NO];
	}
	
	[tabViewReference setNeedsDisplay:YES];
}


#pragma mark NSAnimation delegate methods

- (void)animationDidEnd:(NSAnimation *)animation {
	[self setIsSliding:NO];
}

- (void)animationDidStop:(NSAnimation *)animation {
	[self setIsSliding:NO];
}

@end
