//
//  NSString+CLAdditions.h
//  Syndication
//
//  Created by Calvin Lough on 3/22/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@interface NSString (CLAdditions)

- (NSString *)ayTrimmedString;
- (NSString *)ayUrlEncodedParameterString;
- (NSString *)ayEscapeXMLString;
- (NSString *)ayUnescapeXMLString;

@end
