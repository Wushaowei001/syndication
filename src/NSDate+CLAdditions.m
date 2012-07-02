//
//  NSDate+CLAdditions.m
//  Syndication
//
//  Created by Calvin Lough on 01/27/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "NSDate+CLAdditions.h"

@implementation NSDate (CLAdditions)

- (NSString *)ayStringForDisplay {
	NSString *display;
	NSDate *now = [NSDate date];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	NSString *receiverDateString = [dateFormatter stringFromDate:self];
	NSString *nowDateString = [dateFormatter stringFromDate:now];
	
	if ([receiverDateString isEqual:nowDateString]) {
		[dateFormatter setDateStyle:NSDateFormatterNoStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		display = [dateFormatter stringFromDate:self];
	} else {
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		display = [dateFormatter stringFromDate:self];
	}
	
	[dateFormatter release];
	
	if (display == nil) {
		return @"";
	}
	
	return display;
}

@end
