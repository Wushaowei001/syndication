//
//  CLDateHelper.h
//  Syndication
//
//  Created by Calvin Lough on 5/7/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

typedef enum {CLDateFormatHintNone, CLDateFormatHintRFC822, CLDateFormatHintRFC3339} CLDateFormatHint;

@interface CLDateHelper : NSObject {

}

+ (NSDate *)dateFromInternetDateTimeString:(NSString *)dateString formatHint:(CLDateFormatHint)hint;
+ (NSDate *)dateFromRFC3339String:(NSString *)dateString;
+ (NSDate *)dateFromRFC822String:(NSString *)dateString;
+ (NSTimeInterval)timeIntervalUntilMidnight;

@end
