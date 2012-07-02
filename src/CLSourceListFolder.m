//
//  CLSourceListFolder.m
//  Syndication
//
//  Created by Calvin Lough on 2/20/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLSourceListFeed.h"
#import "CLSourceListFolder.h"

@implementation CLSourceListFolder

@synthesize dbId;
@synthesize path;
@synthesize parentFolderReference;

- (id)init {
	self = [super init];
	if (self != nil) {
		[self setIsEditable:YES];
		[self setIsDraggable:YES];
		[self setIcon:[NSImage imageNamed:NSImageNameFolder]];
	}
	return self;
}

- (void)dealloc {
	
	// zero weak refs
	for (CLSourceListItem *item in children) {
		if ([item isKindOfClass:[CLSourceListFeed class]]) {
			[(CLSourceListFeed *)item setEnclosingFolderReference:nil];
		} else if ([item isKindOfClass:[CLSourceListFolder class]]) {
			[(CLSourceListFolder *)item setParentFolderReference:nil];
		}
	}
	
	[path release];
	
	[super dealloc];
}

@end
