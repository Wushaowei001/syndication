//
//  CLSourceListTextFieldCell.h
//  Syndication
//
//  Created by Calvin Lough on 01/12/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@interface CLSourceListTextFieldCell : NSTextFieldCell {
	BOOL isEditingOrSelecting;
	NSUInteger badgeWidth;
	NSUInteger iconWidth;
	BOOL rowIsSelected;
}

@property (assign, nonatomic) NSUInteger badgeWidth;
@property (assign, nonatomic) NSUInteger iconWidth;
@property (assign, nonatomic) BOOL rowIsSelected;

- (NSRect)drawingRectForBounds:(NSRect)theRect;
- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength;
- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent;
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSRect)modifyRectToAccountForIconAndBadge:(NSRect)rect;

@end
