//
//  CLTableView.m
//  Syndication
//
//  Created by Calvin Lough on 5/2/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLTableView.h"

@implementation CLTableView

@synthesize classicViewReference;

// best
//[NSColor colorWithCalibratedRed:0.871 green:0.910 blue:0.960 alpha:1.0]

// good
//[NSColor colorWithCalibratedRed:0.847 green:0.882 blue:0.928 alpha:1.0]
//[NSColor colorWithCalibratedRed:0.851 green:0.890 blue:0.940 alpha:1.0]
//[NSColor colorWithCalibratedRed:0.871 green:0.906 blue:0.941 alpha:1.0]

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
	
	NSIndexSet *selectedIndexes = [self selectedRowIndexes];
	
	if ([selectedIndexes count] > 0) {
		NSUInteger firstIndex = [selectedIndexes firstIndex];
		NSRect selectionRect = [self rectOfRow:firstIndex];
		selectionRect.size.height = selectionRect.size.height - 1;
		
		if (TABLE_VIEW_SELECTION_STYLE == CLTableViewImageStyle) {
			
			NSImage *backgroundImage;
			
			if ([[self window] isKeyWindow] && (NSResponder *)self == [[self window] firstResponder]) {
				backgroundImage = [NSImage imageNamed:@"tableHighlightFocused"];
			} else {
				backgroundImage = [NSImage imageNamed:@"tableHighlight"];
			}
			
			[backgroundImage setScalesWhenResized:YES];
			[backgroundImage setFlipped:YES];
			[backgroundImage setSize:selectionRect.size];
			
			NSRect imageRect = NSMakeRect(0, 0, selectionRect.size.width, selectionRect.size.height);
			
			[backgroundImage drawInRect:selectionRect fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
			
		} else {
		
			if ([[self window] isKeyWindow] && (NSResponder *)self == [[self window] firstResponder]) {
				[[NSColor colorWithCalibratedRed:0.871 green:0.910 blue:0.960 alpha:1.0] set];
			} else {
				[[NSColor colorWithCalibratedWhite:0.91 alpha:1.0] set];
			}
			
			[NSBezierPath fillRect:selectionRect];
		}
	}
}

- (void)drawGridInClipRect:(NSRect)rect {
	
	NSRect frame = [self frame];
	NSInteger rowHeight = [self rowHeight] + [self intercellSpacing].height;
	NSInteger selectedRow = [self selectedRow];
	NSInteger firstRow = floor(rect.origin.y / rowHeight);
	NSInteger numberOfRows = ceil(rect.size.height / rowHeight);
	NSRange rowRange = NSMakeRange(firstRow, numberOfRows);
	
	for (NSInteger i = rowRange.location; i < (NSInteger)NSMaxRange(rowRange); i++) {
		
		if (selectedRow >= 0 && i == (selectedRow - 1)) { // upper border of selected row
			[[NSColor colorWithCalibratedWhite:0.76 alpha:1.0] set];
		} else if (selectedRow >= 0 && i == selectedRow) { // bottom border of selected row
			[[NSColor colorWithCalibratedWhite:0.76 alpha:1.0] set];
		} else {
			[[self gridColor] set];
		}
		
		NSRect rowRect = NSMakeRect(0, (i * rowHeight), frame.size.width, rowHeight);
		[NSBezierPath strokeLineFromPoint:NSMakePoint(rowRect.origin.x, rowRect.origin.y+rowRect.size.height-0.5)
								  toPoint:NSMakePoint(rowRect.origin.x + rowRect.size.width, rowRect.origin.y+rowRect.size.height-0.5)];
    }
}

@end
