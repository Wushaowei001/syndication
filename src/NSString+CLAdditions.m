//
//  NSString+CLAdditions.m
//  Syndication
//
//  Created by Calvin Lough on 3/22/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "NSString+CLAdditions.h"

@implementation NSString (CLAdditions)

- (NSString *)ayTrimmedString {
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)ayUrlEncodedParameterString {
	NSString *encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, CFSTR("!*'\"();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
	return [encodedString autorelease];
}

- (NSString *)ayEscapeXMLString {
	NSString *escapedString = (NSString *)CFXMLCreateStringByEscapingEntities(NULL, (CFStringRef)self, NULL);
	return [escapedString autorelease];
}

- (NSString *)ayUnescapeXMLString {
	NSString *unescapedString = (NSString *)CFXMLCreateStringByUnescapingEntities(NULL, (CFStringRef)self, NULL);
	return [unescapedString autorelease];
}

@end
