//
//  NSImage+CLAdditions.m
//  Syndication
//
//  Created by Calvin Lough on 01/06/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "NSImage+CLAdditions.h"

@implementation NSImage (CLAdditions)

- (NSImage *)ayTintedImageWithColor:(NSColor *)tint {
	NSSize size = [self size];
	NSRect imageBounds = NSMakeRect(0, 0, size.width, size.height);    
	
	NSImage *copiedImage = [self copy];
	
	[copiedImage lockFocus];
	
	[tint set];
	NSRectFillUsingOperation(imageBounds, NSCompositeSourceAtop);
	
	[copiedImage unlockFocus];  
	
	return [copiedImage autorelease];
}

- (NSImage *)ayThumbnail:(NSSize)size {
	BOOL originalScalesValue = [self scalesWhenResized];
	NSSize originalSize = [self size];
	[self setScalesWhenResized:YES];
	
	NSImage *imageThumb = [[[NSImage alloc] initWithSize:size] autorelease];
	[imageThumb lockFocus];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[self setSize:size];
	[self compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	[imageThumb unlockFocus];
	
	[self setScalesWhenResized:originalScalesValue];
	[self setSize:originalSize];
	
	return imageThumb;
}

@end
