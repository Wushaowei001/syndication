//
//  CLPreferencesWindow.m
//  Syndication
//
//  Created by Calvin Lough on 3/21/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLPreferencesWindow.h"

@implementation CLPreferencesWindow

@synthesize delegate;
@synthesize isSelectingHeadlineFont;
@synthesize isSelectingBodyFont;

- (void)keyDown:(NSEvent *)event {
	NSString *chars = [event characters];
	unichar character = [chars characterAtIndex:0];
	
	if (character == CLEscapeCharacter) {
		[self close];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	
	// disable toolbar toggling
	if ([menuItem action] == @selector(toggleToolbarShown:)) {
		return NO;
	}
	
	return [super validateMenuItem:menuItem];
}

- (void)changeFont:(id)sender {
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *panelFont = [fontManager convertFont:[fontManager selectedFont]];
	
	if (isSelectingHeadlineFont) {
		[delegate preferencesWindowUserDidSelectHeadlineFont:panelFont];
	} else if (isSelectingBodyFont) {
		[delegate preferencesWindowUserDidSelectBodyFont:panelFont];
	}
}

- (void)close {
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	[[fontManager fontPanel:YES] close];
	
	[super close];
}

@end
