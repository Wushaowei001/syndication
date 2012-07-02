//
//  CLDateHelper.m
//  Syndication
//
//  Created by Calvin Lough on 5/7/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLDateHelper.h"

@implementation CLDateHelper

+ (NSDate *)dateFromInternetDateTimeString:(NSString *)dateString formatHint:(CLDateFormatHint)hint {
	
	NSDate *date;
	
	if (hint != CLDateFormatHintRFC3339) {
		
		// try RFC822 first
		date = [CLDateHelper dateFromRFC822String:dateString];
		
		if (!date) {
			date = [CLDateHelper dateFromRFC3339String:dateString];
		}
		
	} else {
		
		// try RFC3339 first
		date = [CLDateHelper dateFromRFC3339String:dateString];
		
		if (!date) {
			date = [CLDateHelper dateFromRFC822String:dateString];
		}
	}
	
	return date;
}

// See http://www.faqs.org/rfcs/rfc822.html
+ (NSDate *)dateFromRFC822String:(NSString *)dateString {
	
	NSDateFormatter *dateFormatter;
	NSLocale *en_US_POSIX = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:en_US_POSIX];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	[en_US_POSIX release];
	
	NSDate *date = nil;
	NSString *RFC822String = [[NSString stringWithString:dateString] uppercaseString];
	RFC822String = [RFC822String stringByReplacingOccurrencesOfString:@" Z" withString:@" GMT"];
	
	if ([RFC822String rangeOfString:@","].location != NSNotFound) {
		
		if (!date) { // Sun, 19 May 2002 15:21:36 GMT
			[dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss zzz"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
		
		if (!date) { // Sun, 19 May 2002 15:21 GMT
			[dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm zzz"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
		
		if (!date) { // Sun, 19 May 2002 15:21:36
			[dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
		
		if (!date) { // Sun, 19 May 2002 15:21
			[dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
		
	} else {
		
		if (!date) { // 19 May 2002 15:21:36 GMT
			[dateFormatter setDateFormat:@"d MMM yyyy HH:mm:ss zzz"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
		
		if (!date) { // 19 May 2002 15:21 GMT
			[dateFormatter setDateFormat:@"d MMM yyyy HH:mm zzz"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
		
		if (!date) { // 19 May 2002 15:21:36
			[dateFormatter setDateFormat:@"d MMM yyyy HH:mm:ss"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
		
		if (!date) { // 19 May 2002 15:21
			[dateFormatter setDateFormat:@"d MMM yyyy HH:mm"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
	}
	
	[dateFormatter release];
	
	return date;
	
}

// See http://www.faqs.org/rfcs/rfc3339.html
+ (NSDate *)dateFromRFC3339String:(NSString *)dateString {
	
	NSDateFormatter *dateFormatter = nil;
	NSLocale *en_US_POSIX = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:en_US_POSIX];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	[en_US_POSIX release];
	
	NSDate *date = nil;
	NSString *RFC3339String = [[NSString stringWithString:dateString] uppercaseString];
	RFC3339String = [RFC3339String stringByReplacingOccurrencesOfString:@"Z" withString:@"-0000"];
	
	if (RFC3339String.length > 20) {
		RFC3339String = [RFC3339String stringByReplacingOccurrencesOfString:@":" withString:@"" options:0 range:NSMakeRange(20, RFC3339String.length-20)];
	}
	
	if (!date) { // 1996-12-19T16:39:57-0800
		[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"]; 
		date = [dateFormatter dateFromString:RFC3339String];
	}
	
	if (!date) { // 1937-01-01T12:00:27.87+0020
		[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZ"]; 
		date = [dateFormatter dateFromString:RFC3339String];
	}
	
	if (!date) { // 1937-01-01T12:00:27
		[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"]; 
		date = [dateFormatter dateFromString:RFC3339String];
	}
	
	[dateFormatter release];
	
	return date;
}

+ (NSTimeInterval)timeIntervalUntilMidnight {
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *dateComponents = [gregorian components:(NSHourCalendarUnit  | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:[NSDate date]];
	NSInteger hour = [dateComponents hour];
	NSInteger minute = [dateComponents minute];
	NSInteger second = [dateComponents second];
	[gregorian release];
	
	NSTimeInterval timeUntilMidnight = ceil(((23 - hour) * TIME_INTERVAL_HOUR) + ((59 - minute) * TIME_INTERVAL_MINUTE) + second);
	
	return timeUntilMidnight;
}

@end
