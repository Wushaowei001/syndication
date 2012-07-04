//
//  CLXMLNode.m
//  Syndication
//
//  Created by Calvin Lough on 3/4/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLXMLNode.h"
#import "NSString+CLAdditions.h"

@implementation CLXMLNode

@synthesize name;
@synthesize nameSpace;
@synthesize content;
@synthesize attributes;
@synthesize children;
@synthesize type;

- (id)init {
	self = [super init];
	if (self != nil) {
		[self setAttributes:[NSMutableDictionary dictionary]];
		[self setChildren:[NSMutableArray array]];
	}
	return self;
}

- (void)dealloc {
	[name release];
	[nameSpace release];
	[content release];
	[attributes release];
	[children release];
	
	[super dealloc];
}

+ (CLXMLNode *)xmlNode {
	return [[[CLXMLNode alloc] init] autorelease];
}

- (NSString *)combinedTextValue {
	if (type == CLXMLTextNode) {
		return [NSString stringWithString:content];
	}
	
	NSMutableString *combinedTextValue = [NSMutableString string];
	
	for (CLXMLNode *child in children) {
		NSString *textValue = [child combinedTextValue];
		
		if (textValue != nil) {
			[combinedTextValue appendString:textValue];
		}
	}
	
	return [combinedTextValue clTrimmedString];
}

@end
