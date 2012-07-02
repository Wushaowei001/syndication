//
//  CLPreferencesWindow.h
//  Syndication
//
//  Created by Calvin Lough on 3/21/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLPreferencesWindowDelegate.h"

@interface CLPreferencesWindow : NSWindow {
	id <CLPreferencesWindowDelegate> delegate;
	BOOL isSelectingHeadlineFont;
	BOOL isSelectingBodyFont;
}

@property (assign, nonatomic) id <CLPreferencesWindowDelegate> delegate;
@property (assign, nonatomic) BOOL isSelectingHeadlineFont;
@property (assign, nonatomic) BOOL isSelectingBodyFont;

@end
