//
//  NSImage+CLAdditions.h
//  Syndication
//
//  Created by Calvin Lough on 01/06/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@interface NSImage (CLAdditions)

- (NSImage *)clTintedImageWithColor:(NSColor *)tint;
- (NSImage *)clThumbnail:(NSSize)size;

@end
