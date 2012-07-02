//
//  CLHTMLFilter.h
//  Syndication
//
//  Created by Calvin Lough on 3/2/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface CLHTMLFilter : NSObject <NSXMLParserDelegate> {
	
}

+ (NSString *)extractPlainTextFromString:(NSString *)string;
+ (NSString *)extractPlainTextFromNode:(NSXMLNode *)node;
+ (NSString *)cleanUrlString:(NSString *)url;

@end
