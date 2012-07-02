//
//  CLWebView.m
//  Syndication
//
//  Created by Calvin Lough on 2/19/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLWebView.h"

@implementation CLWebView

@synthesize tabViewItemReference;

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	
	if (self != nil) {
		[self setPreferencesIdentifier:@"in.calv.syndication"];
		[[self preferences] setMinimumFontSize:9];
		[[self preferences] setDefaultFontSize:16];
		[[self preferences] setDefaultFixedFontSize:16];
		
		[[self preferences] setJavaEnabled:YES];
		[[self preferences] setJavaScriptEnabled:YES];
		[[self preferences] setJavaScriptCanOpenWindowsAutomatically:YES];
		[[self preferences] setPlugInsEnabled:YES];
		
		[[self preferences] setAllowsAnimatedImageLooping:YES];
		[[self preferences] setAllowsAnimatedImages:YES];
		[[self preferences] setLoadsImagesAutomatically:YES];
		
		[[self preferences] setCacheModel:WebCacheModelDocumentViewer];
		[[self preferences] setUsesPageCache:NO];
	}
	
	return self;
}

@end
