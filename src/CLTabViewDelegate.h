//
//  CLTabViewDelegate.h
//  Syndication
//
//  Created by Calvin Lough on 2/18/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@protocol CLTabViewDelegate <NSObject>

- (void)updateTabRectsAndTrackingRects:(BOOL)flag;
- (void)updateAddButtonRectAndTrackingRect:(BOOL)flag;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseDragged:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;

@end
