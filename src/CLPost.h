//
//  CLPost.h
//  Syndication
//
//  Created by Calvin Lough on 01/25/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@class FMResultSet;

@interface CLPost : NSObject {
	NSInteger dbId;
	NSInteger feedDbId;
	NSString *guid;
	NSString *title;
	NSString *feedTitle;
	NSString *feedUrlString;
	NSString *link;
	NSDate *published;
	NSDate *received;
	NSString *author;
	NSString *content;
	NSString *plainTextContent;
	BOOL isRead;
	BOOL isStarred;
	NSMutableArray *enclosures;
}

@property (assign, nonatomic) NSInteger dbId;
@property (assign, nonatomic) NSInteger feedDbId;
@property (copy, nonatomic) NSString *guid;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *feedTitle;
@property (copy, nonatomic) NSString *feedUrlString;
@property (copy, nonatomic) NSString *link;
@property (retain, nonatomic) NSDate *published;
@property (retain, nonatomic) NSDate *received;
@property (copy, nonatomic) NSString *author;
@property (copy, nonatomic) NSString *content;
@property (copy, nonatomic) NSString *plainTextContent;
@property (assign, nonatomic) BOOL isRead;
@property (assign, nonatomic) BOOL isStarred;
@property (retain, nonatomic) NSMutableArray *enclosures;

- (id)initWithResultSet:(FMResultSet *)rs; // note, this doesn't load enclosures
- (void)populateUsingResultSet:(FMResultSet *)rs; // note, this doesn't load enclosures

- (NSComparisonResult)publishedDateCompare:(CLPost *)otherPost;

@end
