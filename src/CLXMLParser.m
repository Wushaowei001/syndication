//
//  CLXMLParser.m
//  Syndication
//
//  Created by Calvin Lough on 01/25/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLXMLNode.h"
#import "CLXMLParser.h"

@implementation CLXMLParser

+ (CLXMLNode *)parseString:(NSString *)xmlString {
	
	xmlDoc *doc = xmlReadMemory([xmlString UTF8String], (unsigned int)[xmlString lengthOfBytesUsingEncoding:NSUTF8StringEncoding], nil, nil, (XML_PARSE_NOERROR | XML_PARSE_NOWARNING | XML_PARSE_NOBLANKS | XML_PARSE_NOCDATA | XML_PARSE_RECOVER | XML_PARSE_COMPACT));
	
	if (doc == nil) {
		return nil;
	}
	
	xmlNode *root = xmlDocGetRootElement(doc);
	
	if (root == nil) {
		xmlFreeDoc(doc);
		return nil;
	}
	
	CLXMLNode *rootNode = [CLXMLNode xmlNode];
	
	[self parseLibNode:root intoObjectNode:rootNode];
	
	xmlFreeDoc(doc);
	
	return rootNode;
}

// recursive function that turns a node returned from libxml2 into 
// an object oriented version that is easier to deal with
+ (void)parseLibNode:(xmlNode *)libNode intoObjectNode:(CLXMLNode *)objectNode {
	
	if (libNode == nil) {
		return;
	}
	
	[objectNode setName:[NSString stringWithUTF8String:(char *)libNode->name]];
	
	if (libNode->type == XML_ELEMENT_NODE) {
		[objectNode setType:CLXMLElementNode];
		
		// namespace
		if (libNode->ns != nil && libNode->ns->prefix != nil) {
			[objectNode setNameSpace:[NSString stringWithUTF8String:(char *)libNode->ns->prefix]];
		}
		
		// parse attributes
		xmlAttr *attrNode = libNode->properties;
		
		while(attrNode && attrNode->name && attrNode->children) {
			NSString *attrName = [NSString stringWithUTF8String:(char *)attrNode->name];
			NSString *attrValue = [NSString stringWithUTF8String:(char *)attrNode->children->content];
			[[objectNode attributes] setValue:attrValue forKey:attrName];
			attrNode = attrNode->next;
		}
		
	} else if (libNode->type == XML_TEXT_NODE) {
		[objectNode setType:CLXMLTextNode];
		xmlChar *content = libNode->content;
		[objectNode setContent:[NSString stringWithUTF8String:(char *)content]];
	}
	
	xmlNode *libChildNode = libNode->children;
	
	while (libChildNode != nil) {
		CLXMLNode *objectChildNode = [CLXMLNode xmlNode];
		[self parseLibNode:libChildNode intoObjectNode:objectChildNode];
		[[objectNode children] addObject:objectChildNode];
		libChildNode = libChildNode->next;
	}
}

@end
