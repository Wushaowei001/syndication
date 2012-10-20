//
//  CLPost.m
//  Syndication
//
//  Created by Calvin Lough on 01/25/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLHTMLFilter.h"
#import "CLPost.h"
#import "FMResultSet.h"
#import "GTMNSString+HTML.h"

@implementation CLPost

@synthesize dbId;
@synthesize feedDbId;
@synthesize guid;
@synthesize title;
@synthesize feedTitle;
@synthesize feedUrlString;
@synthesize link;
@synthesize published;
@synthesize received;
@synthesize author;
@synthesize content;
@synthesize plainTextContent;
@synthesize isRead;
@synthesize isStarred;
@synthesize enclosures;

- (id)init {
	self = [super init];
	if (self != nil) {
		[self setEnclosures:[NSMutableArray array]];
	}
	return self;
}

- (id)initWithJSON:(NSDictionary *)json {
	self = [self init];
	if (self != nil) {
		[self populateUsingJSON:json];
	}
	return self;
}

// note, this doesn't load enclosures
- (id)initWithResultSet:(FMResultSet *)rs {
	self = [self init];
	if (self != nil) {
		[self populateUsingResultSet:rs];
	}
	return self;
}

- (void)dealloc {
	[guid release];
	[title release];
	[feedTitle release];
	[feedUrlString release];
	[link release];
	[published release];
	[received release];
	[author release];
	[content release];
	[plainTextContent release];
	[enclosures release];
	
	[super dealloc];
}

- (void)populateUsingJSON:(NSDictionary *)json {
	[self setTitle:[json objectForKey:@"title"]];
	
	if (title != nil) {
		[self setTitle:[title gtm_stringByUnescapingFromHTML]];
	}
	
	NSDictionary *contentDict = [json objectForKey:@"content"];
	NSString *itemContent = nil;
	
	if (contentDict != nil) {
		itemContent = [contentDict objectForKey:@"content"];
	}
	
	// use "summary" if "content" not available
	if (itemContent == nil) {
		NSDictionary *summary = [json objectForKey:@"summary"];
		
		if (summary != nil) {
			itemContent = [summary objectForKey:@"content"];
		}
	}
	
	[self setContent:itemContent];
	
	if (itemContent != nil) {
		[self setPlainTextContent:[CLHTMLFilter extractPlainTextFromString:itemContent]];
	}
	
	[self setGuid:[json objectForKey:@"id"]];
	NSArray *alternate = [json objectForKey:@"alternate"];
	
	if ([alternate count] > 0) {
		[self setLink:[[alternate objectAtIndex:0] objectForKey:@"href"]];
	}
	
	[self setAuthor:[json objectForKey:@"author"]];
	
	if (author != nil) {
		[self setAuthor:[author gtm_stringByUnescapingFromHTML]];
	}
	
	NSNumber *itemPublishedNumber = [json objectForKey:@"crawlTimeMsec"];
	
	if (itemPublishedNumber != nil) {
		NSTimeInterval itemPublishedInterval = ([itemPublishedNumber doubleValue] / 1000.0);
		[self setPublished:[NSDate dateWithTimeIntervalSince1970:itemPublishedInterval]];
	}
	
	NSArray *categories = [json objectForKey:@"categories"];
	[self setIsRead:NO];
	
	if ([categories count] > 0) {
		for (NSString *category in categories) {
			if ([category hasSuffix:@"state/com.google/read"]) {
				[self setIsRead:YES];
			}
		}
	}
	
	NSNumber *isReadStateLocked = [json objectForKey:@"isReadStateLocked"];
	
	if (isReadStateLocked != nil && [isReadStateLocked boolValue] == YES) {
		[self setIsRead:YES];
	}
	
	NSArray *enclosureArray = [json objectForKey:@"enclosure"];
	
	if ([enclosureArray count] > 0) {
		for (NSDictionary *enclosure in enclosureArray) {
			NSString *enclosureUrl = [enclosure objectForKey:@"href"];
			[enclosures addObject:enclosureUrl];
		}
	}
}

- (void)populateUsingResultSet:(FMResultSet *)rs {
	[self setDbId:[rs longForColumn:@"Id"]];
	[self setFeedDbId:[rs longForColumn:@"FeedId"]];
	[self setGuid:[rs stringForColumn:@"Guid"]];
	[self setTitle:[rs stringForColumn:@"Title"]];
	[self setFeedTitle:[rs stringForColumn:@"FeedTitle"]];
	[self setFeedUrlString:[rs stringForColumn:@"FeedUrlString"]];
	[self setLink:[rs stringForColumn:@"Link"]];
	[self setPublished:[rs dateForColumn:@"Published"]];
	[self setReceived:[rs dateForColumn:@"Received"]];
	[self setAuthor:[rs stringForColumn:@"Author"]];
	[self setContent:[rs stringForColumn:@"Content"]];
	[self setPlainTextContent:[rs stringForColumn:@"PlainTextContent"]];
	[self setIsRead:[rs boolForColumn:@"IsRead"]];
	[self setIsStarred:[rs boolForColumn:@"IsStarred"]];
}

- (NSComparisonResult)publishedDateCompare:(CLPost *)otherPost {
	return [published compare:[otherPost published]];
}

@end
