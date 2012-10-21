//
//  CLTableViewTextFieldCell.m
//  Syndication
//
//  Created by Calvin Lough on 5/4/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLPost.h"
#import "CLTableView.h"
#import "CLTableViewTextFieldCell.h"
#import "NSDate+CLAdditions.h"
#import "GTMNSString+HTML.h"

@implementation CLTableViewTextFieldCell

static NSImage *unreadDot;

@synthesize delegate;
@synthesize rowIndex;
@synthesize tableViewReference;

+ (void)initialize {
	NSString *unreadDotName = [[NSBundle mainBundle] pathForResource:@"unreadDot" ofType:@"png"];
	unreadDot = [[NSImage alloc] initWithContentsOfFile:unreadDotName];
	[unreadDot setFlipped:YES];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	BOOL isKeyWindow = [[tableViewReference window] isKeyWindow];
	BOOL isFirstResponder = ((NSResponder *)tableViewReference == [[tableViewReference window] firstResponder]);
	BOOL isSelectedRow = [[tableViewReference selectedRowIndexes] containsIndex:rowIndex];
	
	NSFont *font = [NSFont fontWithName:@"HelveticaNeue" size:13];
	NSFont *boldFont = [NSFont fontWithName:@"HelveticaNeue-Medium" size:13];
	
	CLPost *post = [delegate tableViewTextFieldCell:self postForRow:rowIndex];
	
	if (post == nil) {
		return;
	}
	
	NSRect titleRect = [self titleRectForBounds:cellFrame];
	
	if ([post isRead] == NO && isSelectedRow == NO) {
		NSRect imageRect = NSMakeRect(titleRect.origin.x + 6, titleRect.origin.y + 35, 9, 9);
		[unreadDot drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	}
	
	titleRect = NSMakeRect(titleRect.origin.x + 22, titleRect.origin.y + 1, titleRect.size.width - 27, 20);
	
	// date
	NSString *dateString = [[post received] clStringForDisplay];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:font forKey:NSFontAttributeName];
	
	if (isSelectedRow && (isKeyWindow == NO || isFirstResponder == NO)) {
		[attributes setObject:[NSColor colorWithCalibratedWhite:0.4 alpha:1.0] forKey:NSForegroundColorAttributeName];
	} else {
		[attributes setObject:[NSColor colorWithCalibratedRed:0.163 green:0.357 blue:0.840 alpha:1.0] forKey:NSForegroundColorAttributeName];
	}
	
	NSAttributedString *attributedDateString = [[NSAttributedString alloc] initWithString:dateString attributes:attributes];
	
	NSRect dateRectSize = [dateString boundingRectWithSize:NSZeroSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
	NSInteger dateRectWidth = (NSInteger)ceil(dateRectSize.size.width);
	NSRect dateRect = NSMakeRect(titleRect.origin.x + titleRect.size.width - dateRectWidth, titleRect.origin.y, dateRectWidth, titleRect.size.height);
	
	[attributedDateString drawInRect:dateRect];
	[attributedDateString release];
	
	// feed title
	NSString *feedTitle = [post feedTitle];
	
	if (feedTitle == nil) {
		feedTitle = [post feedUrlString];
	}
	
	if (feedTitle == nil) {
		feedTitle = @"";
	}
	
	[attributes setObject:boldFont forKey:NSFontAttributeName];
	
	if (TABLE_VIEW_SELECTION_STYLE == CLTableViewImageStyle && isSelectedRow) {
		[attributes setObject:[NSColor colorWithCalibratedWhite:0.945 alpha:1.0] forKey:NSForegroundColorAttributeName];
	} else {
		[attributes setObject:[NSColor colorWithCalibratedWhite:0.015 alpha:1.0] forKey:NSForegroundColorAttributeName];
	}
	
	NSRect titleDrawRect = NSMakeRect(titleRect.origin.x, titleRect.origin.y, titleRect.size.width - dateRectWidth - 7, titleRect.size.height);
	
	[feedTitle drawWithRect:titleDrawRect options:(NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin) attributes:attributes];
	
	// post title
	NSString *postTitle = [post title];
	
	if (postTitle == nil || [postTitle length] == 0) {
		postTitle = @"(Untitled)";
	}
	
	NSRect bylineRect = NSMakeRect(titleRect.origin.x, titleRect.origin.y + 19, titleRect.size.width, titleRect.size.height);
	
	[attributes setObject:font forKey:NSFontAttributeName];
	
	[postTitle drawWithRect:bylineRect options:(NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin) attributes:attributes];
	
	// summary
	NSString *summary = [post plainTextContent];
	
	if (summary == nil) {
		summary = @"";
	}
	
	summary = [[summary componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
	
	NSRect summaryRect = NSMakeRect(titleRect.origin.x, titleRect.origin.y + 40, titleRect.size.width, 35);
	
	attributes = [NSMutableDictionary dictionary];
	[attributes setObject:font forKey:NSFontAttributeName];
	
	if (TABLE_VIEW_SELECTION_STYLE == CLTableViewImageStyle && isSelectedRow) {
		[attributes setObject:[NSColor colorWithCalibratedWhite:0.845 alpha:1.0] forKey:NSForegroundColorAttributeName];
	} else {
		[attributes setObject:[NSColor colorWithCalibratedWhite:0.38 alpha:1.0] forKey:NSForegroundColorAttributeName];
	}
	
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paragraphStyle setMaximumLineHeight:16.0];
	[attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
	[paragraphStyle release];
	
	[summary drawWithRect:summaryRect options:(NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin) attributes:attributes];
}

@end
