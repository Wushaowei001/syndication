//
//  CLTimelineViewItem.m
//  Syndication
//
//  Created by Calvin Lough on 02/08/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLPost.h"
#import "CLTabViewItem.h"
#import "CLTimelineView.h"
#import "CLTimelineViewItem.h"
#import "CLTimelineViewItemView.h"
#import "CLWebView.h"
#import "GTMNSString+HTML.h"
#import "NSString+CLAdditions.h"

@implementation CLTimelineViewItem

@synthesize timelineViewReference;
@synthesize view;
@synthesize webView;
@synthesize height;
@synthesize heightAtLastUpdate;
@synthesize isNewPost;
@synthesize isSelected;
@synthesize isRead;
@synthesize postDbId;
@synthesize feedDbId;
@synthesize postDate;
@synthesize postUrl;
@synthesize heightUpdateTimer;
@synthesize heightUpdateCount;

- (id)init {
    self = [super init];
	
	if (self != nil) {
        if (![NSBundle loadNibNamed:@"CLTimelineViewItem" owner:self]) {
            [self release];
            self = nil;
        }
    }
	
	if (self != nil) {
		[view setTimelineViewItemReference:self];
		
		[[[webView mainFrame] frameView] setAllowsScrolling:NO];
		[webView setDrawsBackground:NO];
		
		[self setHeight:TIMELINE_ITEM_DEFAULT_HEIGHT];
		[self setIsNewPost:YES];
	}
	
    return self;
}

- (void)dealloc {
	
	// zero the weak reference
	[view setTimelineViewItemReference:nil];
	
	[webView stopLoading:self];
	[webView setTabViewItemReference:nil];
	[webView setFrameLoadDelegate:nil];
	[webView setPolicyDelegate:nil];
	[webView setUIDelegate:nil];
	
	if (heightUpdateTimer != nil) {
		if ([heightUpdateTimer isValid]) {
			[heightUpdateTimer invalidate];
		}
	}
	
	[view release]; // send a release message to root object of the nib file
	[postDate release];
	[postUrl release];
	[heightUpdateTimer release];
	
	[super dealloc];
}

- (void)updateClassNames {
	if (isSelected) {
		[webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('post').className='selected'"];
	} else if (isRead) {
		[webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('post').className='read'"];
	} else {
		[webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('post').className=''"];
	}
}

- (BOOL)updateHeight {
	
	BOOL heightDidChange = NO;
	CGFloat newHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('post').clientHeight"] doubleValue];
	CGFloat margins = 12.0;
	
	newHeight = newHeight + margins;
	
	if (newHeight < TIMELINE_ITEM_DEFAULT_HEIGHT) {
		newHeight = TIMELINE_ITEM_DEFAULT_HEIGHT;
	}
	
	if (newHeight != height) {
		heightDidChange = YES;
	}
	
	[self setHeight:newHeight];
	
	NSRect viewRect = [view frame];
	NSRect newViewRect = NSMakeRect(viewRect.origin.x, viewRect.origin.y, viewRect.size.width, height);
	[view setFrame:newViewRect];
	
	return heightDidChange;
}

- (void)updateUsingPost:(CLPost *)post headlineFontName:(NSString *)headlineFontName headlineFontSize:(CGFloat)headlineFontSize bodyFontName:(NSString *)bodyFontName bodyFontSize:(CGFloat)bodyFontSize {
	
	NSMutableString *htmlString = [NSMutableString string];
	
	//-webkit-box-shadow: 0 0 1px rgb(170, 170, 170);
	
	[htmlString appendString:@"<html onClick=\"webScriptHelper.selectItem()\"><head>"];
	[htmlString appendString:CSS_FORMAT_STRING];
	[htmlString appendString:@"<style type=\"text/css\">#post {margin: 9px 5px 3px; background: white; border: 1px solid rgb(180, 180, 180); -webkit-border-radius: 5px} #post.read #postHeadline, #post.read #postHeadline a {color: rgb(100, 100, 100)} #post.selected {border: 1px solid rgb(130, 130, 130)} #postContent {padding: 12px 18px 18px} #postEnclosures {padding: 0 17px 12px}</style>"];
	[htmlString appendFormat:@"<style type=\"text/css\">body {font: %fpt/1.35em '%@', sans-serif} th, td {font-size: %fpt} #postHeadline {font: %fpt '%@', sans-serif}</style>", bodyFontSize, bodyFontName, bodyFontSize, headlineFontSize, headlineFontName];
	
	[htmlString appendString:@"</head><body>"];
	
	if (isRead) {
		[htmlString appendString:@"<div id=\"post\" class=\"read\">"];
	} else {
		[htmlString appendString:@"<div id=\"post\">"];
	}
	
	[htmlString appendString:@"<div id=\"postContent\">"];
	
	NSString *title = [post title];
	
	if (title == nil || [title length] == 0) {
		title = @"(Untitled)";
	}
	
	title = [title gtm_stringByEscapingForHTML];
	
	[htmlString appendString:@"<div id=\"postHeadline\">"];
	
	if ([post link] != nil) {
		[htmlString appendFormat:@"<a href=\"%@\">%@</a>", [post link], title];
	} else {
		[htmlString appendString:title];
	}
	
	[htmlString appendString:@"</div>"];
	
	BOOL hasFeedTitle = ([post feedTitle] != nil && [[post feedTitle] length] > 0);
	BOOL hasAuthor = ([post author] != nil && [[post author] length] > 0);
	
	[htmlString appendString:@"<div class=\"postMeta\">"];
	
	if (hasFeedTitle) {
		[htmlString appendString:[[post feedTitle] gtm_stringByEscapingForHTML]];
	}
	
	if (hasAuthor) {
		if (hasFeedTitle) {
			[htmlString appendString:@" · "];
		}
		
		[htmlString appendString:[[post author] gtm_stringByEscapingForHTML]];
	}
	
	if (hasFeedTitle || hasAuthor) {
		[htmlString appendString:@" · "];
	}
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	NSString *dateString = [dateFormatter stringFromDate:[post received]];
	[dateFormatter release];
	
	[htmlString appendString:dateString];
	
	[htmlString appendString:@"</div>"];
	
	[htmlString appendString:@"<div class=\"fakeHR\"></div>"];
	
	[htmlString appendString:@"<div style=\"overflow: auto\">"];
	
	if ([post content] != nil) {
		[htmlString appendString:[post content]];
	}
	
	[htmlString appendString:@"</div></div>"];
	
	if ([[post enclosures] count] > 0) {
		[htmlString appendString:@"<div id=\"postEnclosures\">"];
		
		if ([[post enclosures] count] == 1) {
			[htmlString appendString:@"<div id=\"postEnclosureTitle\">ENCLOSURE</div>"];
		} else {
			[htmlString appendString:@"<div id=\"postEnclosureTitle\">ENCLOSURES</div>"];
		}
	}
	
	for (NSString *enclosure in [post enclosures]) {
		NSString *enclosureDisplay = enclosure;
		NSURL *enclosureUrl = [NSURL URLWithString:enclosure];
		
		if (enclosureUrl != nil && [enclosureUrl lastPathComponent] != nil) {
			enclosureDisplay = [enclosureUrl lastPathComponent];
		}
		
		[htmlString appendString:[NSString stringWithFormat:@"<div class=\"postEnclosure\"><a href=\"%@\">%@</a></div>", enclosure, enclosureDisplay]];
	}
	
	if ([[post enclosures] count] > 0) {
		[htmlString appendString:@"</div>"];
	}
	
	[htmlString appendString:@"</div>"];
	[htmlString appendString:@"</body></html>"];
	
	[[webView mainFrame] loadHTMLString:htmlString baseURL:nil];
}

@end
