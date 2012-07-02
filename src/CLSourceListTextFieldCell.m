//
//  CLSourceListTextField.m
//  Syndication
//
//  Created by Calvin Lough on 01/12/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLSourceListTextFieldCell.h"

@implementation CLSourceListTextFieldCell

@synthesize badgeWidth;
@synthesize iconWidth;
@synthesize rowIsSelected;

- (NSRect)drawingRectForBounds:(NSRect)theRect {
	
	// Get the parent's idea of where we should draw
	NSRect newRect = [super drawingRectForBounds:theRect];
	
	// When the text field is being 
	// edited or selected, we have to turn off the magic because it screws up 
	// the configuration of the field editor.  We sneak around this by 
	// intercepting selectWithFrame and editWithFrame and sneaking a 
	// reduced, centered rect in at the last minute.
	if (isEditingOrSelecting == NO) {
		
		// Get our ideal size for current text
		NSSize textSize = [self cellSizeForBounds:theRect];
		
		// Center that in the proposed rect
		CGFloat heightDelta = newRect.size.height - textSize.height;
		
		if (heightDelta > 0) {
			newRect.size.height -= heightDelta;
			newRect.origin.y += (heightDelta / 2);
		}
	}
	
	return newRect;
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength {
	aRect = [self drawingRectForBounds:aRect];
	aRect = [self modifyRectToAccountForIconAndBadge:aRect];
	
	isEditingOrSelecting = YES;	
	[super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
	isEditingOrSelecting = NO;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
	aRect = [self drawingRectForBounds:aRect];
	aRect = [self modifyRectToAccountForIconAndBadge:aRect];
	
	isEditingOrSelecting = YES;
	[super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
	isEditingOrSelecting = NO;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	cellFrame = [self modifyRectToAccountForIconAndBadge:cellFrame];
	
	[super drawWithFrame:cellFrame inView:controlView];
}

- (NSRect)modifyRectToAccountForIconAndBadge:(NSRect)rect {
	
	if (iconWidth > 0) {
		rect.origin.x += (CGFloat)(SOURCE_LIST_ICON_PADDING_LEFT + iconWidth + SOURCE_LIST_ICON_PADDING_RIGHT);
		rect.size.width -= (CGFloat)(SOURCE_LIST_ICON_PADDING_LEFT + iconWidth + SOURCE_LIST_ICON_PADDING_RIGHT);
	}
	
	if (badgeWidth > 0) {
		rect.size.width -= (CGFloat)(badgeWidth + SOURCE_LIST_BADGE_PADDING);
	}
	
	return rect;
}

@end
