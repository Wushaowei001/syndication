//
//  CLSourceList.h
//  Syndication
//
//  Created by Calvin Lough on 01/12/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@interface CLSourceList : NSOutlineView {
	BOOL isWindowFocused;
}

@property (assign, nonatomic) BOOL isWindowFocused;

- (void)drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect;
+ (NSSize)sizeOfBadgeForItem:(id)rowItem;
- (void)drawBadgeForRow:(NSInteger)rowIndex inRect:(NSRect)badgeFrame;

@end
