//
//  CLHTMLFilter.m
//  Syndication
//
//  Created by Calvin Lough on 3/2/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLHTMLFilter.h"
#import "NSString+CLAdditions.h"

@implementation CLHTMLFilter

/* static NSArray *tagWhiteList;
static NSArray *attributeWhiteList;

+ (void)initialize {
	tagWhiteList = [[NSArray alloc] initWithObjects:@"a", @"abbr", @"acronym", @"address", @"area", @"b", @"big", @"blockquote", @"br", @"button", @"caption", @"center", @"cite", @"code", @"col", @"colgroup", @"dd", @"del", @"dfn", @"dir", @"div", @"dl", @"dt", @"em", @"embed", @"fieldset", @"font", @"form", @"h1", @"h2", @"h3", @"h4", @"h5", @"h6", @"hr", @"i", @"img", @"input", @"ins", @"kbd", @"label", @"legend", @"li", @"map", @"menu", @"object", @"ol", @"optgroup", @"option", @"p", @"param", @"pre", @"q", @"s", @"samp", @"select", @"small", @"span", @"strike", @"strong", @"sub", @"sup", @"table", @"tbody", @"td", @"textarea", @"tfoot", @"th", @"thead", @"tr", @"tt", @"u", @"ul", @"var", nil];	
	attributeWhiteList = [[NSArray alloc] initWithObjects:@"abbr", @"accept", @"accept-charset", @"accesskey", @"action", @"align", @"allowfullscreen", @"alt", @"axis", @"border", @"cellpadding", @"cellspacing", @"char", @"charoff", @"charset", @"checked", @"cite", @"class", @"clear", @"cols", @"colspan", @"color", @"compact", @"coords", @"datetime", @"dir", @"disabled", @"enctype", @"for", @"frame", @"headers", @"height", @"href", @"hreflang", @"hspace", @"id", @"ismap", @"label", @"lang", @"longdesc", @"maxlength", @"media", @"method", @"multiple", @"name", @"nohref", @"noshade", @"nowrap", @"prompt", @"readonly", @"rel", @"rev", @"rows", @"rowspan", @"rules", @"scope", @"selected", @"shape", @"size", @"span", @"src", @"start", @"summary", @"tabindex", @"target", @"title", @"type", @"usemap", @"valign", @"value", @"vspace", @"width", nil];
} */

# pragma mark convenience & helper methods

+ (NSString *)extractPlainTextFromString:(NSString *)htmlString {
	
	NSString *plainTextString;
	
	if (htmlString == nil || [htmlString length] == 0) {
		return @"";
	}
	
	NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithXMLString:htmlString options:NSXMLDocumentTidyHTML error:nil];
	
	if (xmlDocument == nil) {
		return @"";
	}
	
	plainTextString = [CLHTMLFilter extractPlainTextFromNode:xmlDocument];
	
	[xmlDocument release];
	
	if (plainTextString != nil) {
		plainTextString = [plainTextString ayTrimmedString];
	}
	
	return plainTextString;
}

+ (NSString *)extractPlainTextFromNode:(NSXMLNode *)node {
	NSMutableString *returnValue = [NSMutableString string];
	
	if ([node kind] == NSXMLTextKind) {
		[returnValue appendString:[node stringValue]];
	} else if ([node kind] == NSXMLElementKind || [node kind] == NSXMLDocumentKind) {
		if ([[node name] isEqual:@"script"] == NO && [[node name] isEqual:@"style"] == NO) {
			for (NSXMLNode *child in [node children]) {
				[returnValue appendString:[CLHTMLFilter extractPlainTextFromNode:child]];
			}
		}
	}
	
	return returnValue;
}

+ (NSString *)cleanUrlString:(NSString *)urlString {
	
	if (urlString == nil || [urlString isEqual:@""]) {
		return urlString;
	}
	
	urlString = [urlString ayTrimmedString];
	
	NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:@"SyndicationPB"];
	[pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	
	@try {
		if ([pasteboard setString:urlString forType:NSStringPboardType]) {
			NSURL *urlToLoad = [WebView URLFromPasteboard:pasteboard];
			urlString = [urlToLoad absoluteString];
		}
	} @catch (...) {
		urlString = @"";
		CLLog(@"ignoring url: %@", urlString);
	}
	
	return urlString;
}

@end
