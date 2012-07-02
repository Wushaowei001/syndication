//
//  CLTabView.m
//  Syndication
//
//  Created by Calvin Lough on 01/14/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLTabView.h"
#import "CLTabViewItem.h"

@implementation CLTabView

static NSImage *tabBarBack;
static NSImage *addButtonHover;

@synthesize delegate;
@synthesize tabViewItems;
@synthesize selectedTabViewItem;
@synthesize displayView;
@synthesize addButtonRect;
@synthesize isAddButtonHover;
@synthesize dragTabViewItem;

+ (void)initialize {
	NSString *tabBarBackName = [[NSBundle mainBundle] pathForResource:@"tabBarBack" ofType:@"png"];
	tabBarBack = [[NSImage alloc] initWithContentsOfFile:tabBarBackName];
	
	NSString *addButtonHoverName = [[NSBundle mainBundle] pathForResource:@"tabHover" ofType:@"png"];
	addButtonHover = [[NSImage alloc] initWithContentsOfFile:addButtonHoverName];
}

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	
    if (self != nil) {
		[self setTabViewItems:[NSMutableArray array]];
    }
	
    return self;
}

- (void)dealloc {
	
	// zero each weak ref
	if (tabViewItems != nil) {
		for (CLTabViewItem *tabViewItem in tabViewItems) {
			[tabViewItem setTabViewReference:nil];
		}
	}
	
	[tabViewItems release];
	[selectedTabViewItem release];
	[dragTabViewItem release];
	
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
	
	NSRect frame = [self frame];
	
	if ([self inLiveResize]) {
		[delegate updateTabRectsAndTrackingRects:NO];
		[delegate updateAddButtonRectAndTrackingRect:NO];
	}
	
	if ([tabViewItems count] > 1) {
		
		[tabBarBack drawInRect:NSMakeRect(0, 0, frame.size.width, frame.size.height) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
		
		for (CLTabViewItem *tab in tabViewItems) {
			
			// update spinner status
			if (dragTabViewItem == nil) {
				NSProgressIndicator *spinner = [tab spinner];
				
				if ([tab isLoading] && [spinner isHidden]) {
					[spinner startAnimation:self];
					[spinner setHidden:NO];
				} else if ([tab isLoading] == NO && [spinner isHidden] == NO) {
					[spinner stopAnimation:self];
					[spinner setHidden:YES];
				}
			}
			
			[tab draw];
		}
		
		// if a tab is being dragged, draw it on top
		if (dragTabViewItem != nil) {
			[dragTabViewItem draw];
		}
		
		// add tab button
		if (isAddButtonHover) {
			[addButtonHover drawInRect:addButtonRect fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
		}
		
		NSImage *addTab = [NSImage imageNamed:@"NSAddTemplate"];
		NSRect addTabRect = NSMakeRect(frame.origin.x + frame.size.width - 17, 7, 8, 8);
		[addTab drawInRect:addTabRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.7];
		
		[[NSColor colorWithCalibratedWhite:(140.0f / 255.0f) alpha:1] set];
		NSRect lineRect = NSMakeRect(frame.origin.x + frame.size.width - TABVIEW_ADD_BUTTON_WIDTH, 0, 1, frame.size.height);
		NSRectFill(lineRect);
	}
}

- (void)mouseDown:(NSEvent *)theEvent {
	[delegate mouseDown:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent {
	[delegate mouseDragged:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent {
	[delegate mouseUp:theEvent];
}

@end
