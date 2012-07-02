//
//  CLWebScriptHelper.m
//  Syndication
//
//  Created by Calvin Lough on 3/12/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLWebScriptHelper.h"
#import "CLWindowController.h"

@implementation CLWebScriptHelper

@synthesize windowControllerReference;
@synthesize timelineViewReference;
@synthesize timelineViewItemReference;

+ (CLWebScriptHelper *)webScriptHelper {
	return [[[CLWebScriptHelper alloc] init] autorelease];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
	return NO;
}

- (void)selectItem {
	[windowControllerReference setSelectedItem:timelineViewItemReference forTimelineView:timelineViewReference];
}

@end
