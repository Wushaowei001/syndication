//
//  CLFeedSheetController.m
//  Syndication
//
//  Created by Calvin Lough on 01/10/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLFeedSheetController.h"
#import "CLSourceList.h"
#import "CLWindowController.h"

@implementation CLFeedSheetController

@synthesize mainWindow;
@synthesize addFeedSheet;

- (IBAction)showSheet:(id)sender {	
	[NSApp beginSheet:addFeedSheet modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)hideSheet:(id)sender {
	[NSApp endSheet:addFeedSheet];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

@end
