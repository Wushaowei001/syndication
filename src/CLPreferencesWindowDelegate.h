//
//  CLPreferencesWindowDelegate.h
//  Syndication
//
//  Created by Calvin Lough on 5/19/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@protocol CLPreferencesWindowDelegate <NSWindowDelegate>

- (void)preferencesWindowUserDidSelectHeadlineFont:(NSFont *)font;
- (void)preferencesWindowUserDidSelectBodyFont:(NSFont *)font;

@end
