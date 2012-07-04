//
//  CLClassicView.m
//  Syndication
//
//  Created by Calvin Lough on 5/2/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLClassicView.h"
#import "CLConstants.h"
#import "CLPost.h"
#import "CLSourceListItem.h"
#import "CLTabViewItem.h"
#import "CLTableView.h"
#import "CLWebView.h"
#import "CLWindowController.h"
#import "GTMNSString+HTML.h"
#import "NSScrollView+CLAdditions.h"
#import "NSString+CLAdditions.h"

@implementation CLClassicView

@synthesize tabViewItemReference;
@synthesize view;
@synthesize splitView;
@synthesize tableView;
@synthesize webView;
@synthesize posts;
@synthesize unreadItemsDict;
@synthesize postsMissingFromBottom;
@synthesize displayedPost;
@synthesize informationWebView;
@synthesize shouldIgnoreSelectionChange;

- (id)init {
    self = [super init];
	
	if (self != nil) {
        if (![NSBundle loadNibNamed:@"CLClassicView" owner:self]) {
            [self release];
            self = nil;
        }
    }
	
	if (self != nil) {
		[tableView setClassicViewReference:self];
		
		[self setPosts:[NSMutableArray array]];
		[self setUnreadItemsDict:[NSMutableDictionary dictionary]];
		[self setPostsMissingFromBottom:YES];
	}
	
    return self;
}

- (void)dealloc {
	[webView stopLoading:self];
	[webView setTabViewItemReference:nil];
	[webView setFrameLoadDelegate:nil];
	[webView setPolicyDelegate:nil];
	[webView setUIDelegate:nil];
	
	[tableView setClassicViewReference:nil];
	
	[view release]; // send a release message to root object of the nib file
	[posts release];
	[unreadItemsDict release];
	[displayedPost release];
	
	[super dealloc];
}

- (void)updateUsingPost:(CLPost *)post headlineFontName:(NSString *)headlineFontName headlineFontSize:(CGFloat)headlineFontSize bodyFontName:(NSString *)bodyFontName bodyFontSize:(CGFloat)bodyFontSize {
	
	[self setDisplayedPost:post];
	
	NSMutableString *htmlString = [NSMutableString string];
	
	[htmlString appendString:@"<html><head>"];
	[htmlString appendString:CSS_FORMAT_STRING];
	[htmlString appendString:@"<style type=\"text/css\">#post {margin: 15px 24px 25px}</style>"];
	[htmlString appendFormat:@"<style type=\"text/css\">body {font: %fpt/1.35em '%@', sans-serif} th, td {font-size: %fpt} #postHeadline {font: %fpt '%@', sans-serif}</style>", bodyFontSize, bodyFontName, bodyFontSize, headlineFontSize, headlineFontName];
	[htmlString appendString:@"</head><body>"];
	
	[htmlString appendString:@"<div id=\"post\">"];
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
	
	if ([post content] != nil) {
		[htmlString appendString:[post content]];
	}
	
	[htmlString appendString:@"</div>"];
	
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

- (void)removePostsInRange:(NSRange)range preserveScrollPosition:(BOOL)preserveScroll updateMetadata:(BOOL)updateMetadata ignoreSelection:(BOOL)ignoreSelection {
	
	if (range.length == 0) {
		CLLog(@"range.length == 0");
		return;
	}
	
	if ((range.location + range.length) > [posts count]) {
		CLLog(@"(range.location + range.length) > [posts count]");
		return;
	}
	
	CLSourceListItem *sourceListItem = [tabViewItemReference sourceListItem];
	BOOL isOnlyUnreadItems = (sourceListItem == [[[view window] windowController] sourceListNewItems]);
	NSInteger selectedRow = [tableView selectedRow];
	NSInteger postsRemovedCount = 0;
	NSClipView *clipView = (NSClipView *)[tableView superview];
	NSScrollView *scrollView = (NSScrollView *)[clipView superview];
	CGFloat scrollX = [scrollView documentVisibleRect].origin.x;
	CGFloat oldScrollY = [scrollView documentVisibleRect].origin.y;
	CGFloat scrollY = oldScrollY;
	CGFloat rowHeight = [tableView rowHeight] + [tableView intercellSpacing].height;
	CGFloat firstItemOffset = rowHeight * range.location;
	
	for (NSInteger i=(range.location + range.length - 1); i>=(NSInteger)range.location; i--) {
		CLPost *post = [posts objectAtIndex:i];
		
		if (isOnlyUnreadItems) {
			if ([post isRead] == NO) {
				postsRemovedCount++;
			}
		} else {
			postsRemovedCount++;
		}
		
		if (firstItemOffset < scrollY) {
			scrollY -= rowHeight;
			
			if (scrollY < 0) {
				scrollY = 0;
			}
		}
		
		if ([post isRead] == NO) {
			NSNumber *key = [NSNumber numberWithInteger:[post dbId]];
			[unreadItemsDict removeObjectForKey:key];
		}
		
		[posts removeObjectAtIndex:i];
	}
	
	if (preserveScroll && oldScrollY != scrollY) {
		[scrollView clScrollInstantlyTo:NSMakePoint(scrollX, scrollY)];
	}
	
	if (updateMetadata) {
		if (postsRemovedCount > 0) {
			[self setPostsMissingFromBottom:YES];
		}
	}
	
	if (selectedRow >= (NSInteger)range.location && selectedRow < (NSInteger)(range.location + range.length)) {
		[self setShouldIgnoreSelectionChange:ignoreSelection];
		[tableView deselectAll:self];
	}
	
	[tableView reloadData];
	
	if (selectedRow >= (NSInteger)(range.location + range.length)) {
		selectedRow -= range.length;
		[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
	}
}

@end
