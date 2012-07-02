//
//  CLRequest.m
//  Syndication
//
//  Created by Calvin Lough on 7/2/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLRequest.h"

@implementation CLRequest

@synthesize requestType;
@synthesize specificFeeds;
@synthesize singleFeed;

- (void)dealloc {
	[specificFeeds release];
	[singleFeed release];
	
	[super dealloc];
}

@end
