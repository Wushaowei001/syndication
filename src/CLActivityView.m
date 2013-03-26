//
//  CLActivityView.m
//  Syndication
//
//  Created by Calvin Lough on 5/10/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLActivityView.h"
#import "CLConstants.h"
#import "CLSourceListFeed.h"
#import "CLOperation.h"

@implementation CLActivityView

@synthesize feeds;
@synthesize spinner1;
@synthesize spinner2;

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	
    if (self != nil) {
		NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
		[progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
		[progressIndicator setUsesThreadedAnimation:YES];
		[progressIndicator setHidden:YES];
		[self addSubview:progressIndicator];
		
		[self setSpinner1:progressIndicator];
		[progressIndicator release];
		
		progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
		[progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
		[progressIndicator setUsesThreadedAnimation:YES];
		[progressIndicator setHidden:YES];
		[self addSubview:progressIndicator];
		
		[self setSpinner2:progressIndicator];
		[progressIndicator release];
    }
	
    return self;
}

- (void)dealloc {
	[spinner1 removeFromSuperviewWithoutNeedingDisplay];
	[spinner2 removeFromSuperviewWithoutNeedingDisplay];
	
	[feeds release];
	
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
	
	NSRect rect = [self frame];
	
	[[NSColor colorWithCalibratedRed:0.813 green:0.839 blue:0.874 alpha:1.0] setFill];
	NSRectFill(rect);
	
	NSRect firstRowRect = NSMakeRect(0, 24, rect.size.width, 25);
	[[NSColor colorWithCalibratedRed:0.871 green:0.894 blue:0.918 alpha:1.0] setFill];
	NSRectFill(firstRowRect);
	
	[[NSColor colorWithCalibratedWhite:0.6 alpha:1.0] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(0, 0) toPoint:NSMakePoint(rect.size.width, 0)];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	NSFont *font = [NSFont boldSystemFontOfSize:11.0];
	[attributes setObject:font forKey:NSFontAttributeName];
	[attributes setObject:[NSColor colorWithCalibratedRed:0.369 green:0.376 blue:0.380 alpha:1.0] forKey:NSForegroundColorAttributeName];
	
	NSShadow *textShadow = [[NSShadow alloc] init];
	[textShadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]];
	[textShadow setShadowOffset:NSMakeSize(0, -1)];
	[textShadow setShadowBlurRadius:1.0];
	[attributes setObject:textShadow forKey:NSShadowAttributeName];
	[textShadow release];
	
	NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"ACTIVITY" attributes:attributes];
	
	NSRect titleRect = NSMakeRect(rect.origin.x + 9, rect.origin.y + 5, rect.size.width, 15);
	
	[title drawInRect:titleRect];
	[title release];
	
	NSInteger rowCount = 2;
	NSMutableArray *allFeeds = [NSMutableArray arrayWithArray:feeds];
	NSInteger feedCount = [allFeeds count];
	NSInteger iterationCount = 0;
	NSInteger displayCount = 0;
	
	while (displayCount < rowCount && iterationCount < feedCount) {
		attributes = [NSMutableDictionary dictionary];
		font = [NSFont systemFontOfSize:11.0];
		[attributes setObject:font forKey:NSFontAttributeName];
		NSMutableParagraphStyle *truncateTail = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[truncateTail setLineBreakMode:NSLineBreakByTruncatingTail];
		[attributes setObject:truncateTail forKey:NSParagraphStyleAttributeName];
		[truncateTail release];
		
		CLSourceListFeed *feed = [allFeeds objectAtIndex:iterationCount];
		NSAttributedString *lineText = nil;
		NSImage *lineIcon = nil;
		
		lineText = [[NSAttributedString alloc] initWithString:[feed extractTitleForDisplay] attributes:attributes];
		lineIcon = [feed icon];
		
		if (lineText != nil) {
			
			if (lineIcon == nil) {
				NSString *rssIconName = [[NSBundle mainBundle] pathForResource:@"rssIcon" ofType:@"png"];
				NSImage *defaultIcon = [[[NSImage alloc] initWithContentsOfFile:rssIconName] autorelease];
				
				lineIcon = defaultIcon;
			}
			
			[lineIcon setFlipped:YES];
			
			NSRect iconRect = NSMakeRect(rect.origin.x + 9, rect.origin.y + 28 + (displayCount * 25), 16, 16);
			[lineIcon drawInRect:iconRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
			
			NSRect lineRect = NSMakeRect(rect.origin.x + 30, rect.origin.y + 29 + (displayCount * 25), rect.size.width - 54, 15);
			
			[lineText drawInRect:lineRect];
			[lineText release];
			
			displayCount++;
		}
		
		iterationCount++;
	}
	
	[spinner1 setFrame:NSMakeRect(rect.origin.x + (rect.size.width - 18), rect.origin.y + 29, 14, 14)];
	[spinner2 setFrame:NSMakeRect(rect.origin.x + (rect.size.width - 18), rect.origin.y + 54, 14, 14)];
	
	if (displayCount == 0) {
		[spinner1 setHidden:YES];
		[spinner1 stopAnimation:self];
		[spinner2 setHidden:YES];
		[spinner2 stopAnimation:self];
	} else if (displayCount == 1) {
		[spinner1 setHidden:NO];
		[spinner1 startAnimation:self];
		[spinner2 setHidden:YES];
		[spinner2 stopAnimation:self];
	} else if (displayCount == 2) {
		[spinner1 setHidden:NO];
		[spinner1 startAnimation:self];
		[spinner2 setHidden:NO];
		[spinner2 startAnimation:self];
	}
}

- (BOOL)isFlipped {
	return YES;
}

@end
