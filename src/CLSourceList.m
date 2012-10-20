//
//  CLSourceList.m
//  Syndication
//
//  Created by Calvin Lough on 01/12/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLSourceList.h"
#import "CLSourceListItem.h"
#import "CLSourceListTextFieldCell.h"
#import "CLVersionNumberHelper.h"

#define MIN_BADGE_WIDTH							22.0		//The minimum badge width for each item (default 22.0)
#define BADGE_HEIGHT							14.0		//The badge height for each item (default 14.0)
#define BADGE_MARGIN							5.0			//The spacing between the badge and the cell for that row
#define ROW_RIGHT_MARGIN						5.0			//The spacing between the right edge of the badge and the edge of the table column

#define BADGE_BACKGROUND_COLOR					[NSColor colorWithCalibratedRed:(152/255.0) green:(168/255.0) blue:(202/255.0) alpha:1]
#define BADGE_SELECTED_TEXT_COLOR				[NSColor keyboardFocusIndicatorColor]
#define BADGE_SELECTED_UNFOCUSED_TEXT_COLOR		[NSColor colorWithCalibratedRed:(153/255.0) green:(169/255.0) blue:(203/255.0) alpha:1]
#define BADGE_FONT								[NSFont boldSystemFontOfSize:11]

@implementation CLSourceList

static NSImage *defaultIcon;

@synthesize isWindowFocused;

+ (void)initialize {
	NSString *rssIconName = [[NSBundle mainBundle] pathForResource:@"rssIcon" ofType:@"png"];
	defaultIcon = [[NSImage alloc] initWithContentsOfFile:rssIconName];
}

- (BOOL)acceptsFirstResponder {
	return NO;
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect {
	[[NSColor colorWithCalibratedRed:0.8392 green:0.8667 blue:0.8980 alpha:1.0] set];
	[NSBezierPath fillRect:clipRect];
}

- (void)drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect {
	
	[super drawRow:rowIndex clipRect:clipRect];
	
	NSRect rowRect = [self rectOfRow:rowIndex];
	CLSourceListItem *item = [self itemAtRow:rowIndex];
	
	if ([item badgeValue] > 0) {
		NSSize badgeSize = [CLSourceList sizeOfBadgeForItem:item];
		
		NSRect badgeFrame = NSMakeRect(NSMaxX(rowRect)-badgeSize.width-ROW_RIGHT_MARGIN,
									   NSMidY(rowRect)-(badgeSize.height/2.0),
									   badgeSize.width,
									   badgeSize.height);
		
		[self drawBadgeForRow:rowIndex inRect:badgeFrame];
	}
	
	NSImage *icon = [item icon];
	
	if (icon == nil && [item isGroupItem] == NO) {
		icon = defaultIcon;
	}
	
	if (icon != nil) {
		NSRect frameRect = [self frameOfCellAtColumn:0 row:rowIndex];
		NSRect iconRect = NSMakeRect(frameRect.origin.x + SOURCE_LIST_ICON_PADDING_LEFT, rowRect.origin.y + 2, SOURCE_LIST_ICON_WIDTH, SOURCE_LIST_ICON_HEIGHT);
		
		[icon setFlipped:YES];
		[icon drawInRect:iconRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
	}
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
	
	NSImage *backgroundImage;
	
	if (isWindowFocused) {
		backgroundImage = [NSImage imageNamed:@"outlineHighlightFocused"];
	} else {
		backgroundImage = [NSImage imageNamed:@"outlineHighlight"];
	}
	
	if (backgroundImage) {
		[backgroundImage setScalesWhenResized:YES];
		[backgroundImage setFlipped:YES];
		
		NSRect drawingRect = [self rectOfRow:[self selectedRow]];
		
		[backgroundImage setSize:drawingRect.size];
		
		NSRect imageRect = NSMakeRect(0, 0, drawingRect.size.width, drawingRect.size.height);
		
		[backgroundImage drawInRect:drawingRect fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
	}
}

- (NSRect)frameOfCellAtColumn:(NSInteger)columnIndex row:(NSInteger)rowIndex {
	NSRect frame = [super frameOfCellAtColumn:columnIndex row:rowIndex];
	
	CGFloat shift = 0;
	
	if ([CLVersionNumberHelper isRunningLionOrNewer]) {
		
		if (frame.origin.x > [self indentationPerLevel]) {
			shift = 3;
		}
		
	} else {
		
		if (frame.origin.x > [self indentationPerLevel]) {
			shift = ([self indentationPerLevel] - 2) * -1;
		}
		
		if ((frame.origin.x + shift) == 8) {
			shift = -2;
		}
	}
	
	frame.origin.x += shift;
	frame.size.width -= shift;
	
	return frame;
}

- (NSRect)frameOfOutlineCellAtRow:(NSInteger)rowIndex {
	NSRect frame = [super frameOfOutlineCellAtRow:rowIndex];
	
	if ([CLVersionNumberHelper isRunningLionOrNewer]) {
		frame.origin.x += 4;
	} else {
		if (frame.origin.x > [self indentationPerLevel]) {
			frame.origin.x -= ([self indentationPerLevel] - 2);
		}
	}
	
	return frame;
}

+ (NSSize)sizeOfBadgeForItem:(id)rowItem {
	
	if ([rowItem badgeValue] == 0) {
		return NSZeroSize;
	}
	
	NSAttributedString *badgeAttrString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", [rowItem badgeValue]] attributes:[NSDictionary dictionaryWithObjectsAndKeys:BADGE_FONT, NSFontAttributeName, nil]];
	
	NSSize stringSize = [badgeAttrString size];
	CGFloat width = stringSize.width + (2 * BADGE_MARGIN);
	
	if (width < MIN_BADGE_WIDTH) {
		width = MIN_BADGE_WIDTH;
	}
	
	[badgeAttrString release];
	
	return NSMakeSize(width, BADGE_HEIGHT);
}

- (void)drawBadgeForRow:(NSInteger)rowIndex inRect:(NSRect)badgeFrame {
	
	CLSourceListItem *rowItem = [self itemAtRow:rowIndex];
	
	if ([[self selectedRowIndexes] containsIndex:rowIndex]) {
		badgeFrame.size.height -= 1;
	}
	
	NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame xRadius:(BADGE_HEIGHT/2.0) yRadius:(BADGE_HEIGHT/2.0)];
	
	NSInteger rowBeingEdited = [self editedRow];
	
	NSDictionary *attributes;
	NSColor *backgroundColor;
	
	if ([[self selectedRowIndexes] containsIndex:rowIndex]) {
		backgroundColor = [NSColor whiteColor];
		
		NSColor *textColor;
		
		if (isWindowFocused || rowBeingEdited == rowIndex) {
			textColor = BADGE_SELECTED_TEXT_COLOR;
		} else {
			textColor = BADGE_SELECTED_UNFOCUSED_TEXT_COLOR;
		}
		
		attributes = [[NSDictionary alloc] initWithObjectsAndKeys:BADGE_FONT, NSFontAttributeName, textColor, NSForegroundColorAttributeName, nil];
		
	} else {
		
		NSColor *badgeColor = [NSColor whiteColor];
		
		backgroundColor = BADGE_BACKGROUND_COLOR;
		
		attributes = [[NSDictionary alloc] initWithObjectsAndKeys:BADGE_FONT, NSFontAttributeName, badgeColor, NSForegroundColorAttributeName, nil];
	}
	
	[backgroundColor set];
	[badgePath fill];
	
	NSAttributedString *badgeAttrString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", [rowItem badgeValue]] attributes:attributes];
	NSSize stringSize = [badgeAttrString size];
	NSPoint badgeTextPoint = NSMakePoint(NSMidX(badgeFrame)-(stringSize.width/2.0)+1, NSMidY(badgeFrame)-(stringSize.height/2.0));
	[badgeAttrString drawAtPoint:badgeTextPoint];
	
	[attributes release];
	[badgeAttrString release];
}

@end
