//
//  CLXMLParser.h
//  Syndication
//
//  Created by Calvin Lough on 01/25/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#include <libxml/xmlmemory.h>

@class CLXMLNode;

@interface CLXMLParser : NSObject {
	
}

+ (CLXMLNode *)parseString:(NSString *)xmlString;
+ (void)parseLibNode:(xmlNodePtr)libNode intoObjectNode:(CLXMLNode *)objectNode;

@end
