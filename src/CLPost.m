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
