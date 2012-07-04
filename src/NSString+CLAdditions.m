//
//  NSString+CLAdditions.m
//  Syndication
//
//  Created by Calvin Lough on 3/22/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "NSString+CLAdditions.h"

@implementation NSString (CLAdditions)

- (NSString *)clTrimmedString {
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)clUrlEncodedParameterString {
	NSString *encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, CFSTR("!*'\"();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
	return [encodedString autorelease];
}

- (NSString *)clEscapeXMLString {
	NSString *escapedString = (NSString *)CFXMLCreateStringByEscapingEntities(NULL, (CFStringRef)self, NULL);
	return [escapedString autorelease];
}

- (NSString *)clUnescapeXMLString {
	NSString *unescapedString = (NSString *)CFXMLCreateStringByUnescapingEntities(NULL, (CFStringRef)self, NULL);
	return [unescapedString autorelease];
}

@end
