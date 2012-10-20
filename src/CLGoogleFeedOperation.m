//
//  CLGoogleFeedOperation.m
//  Syndication
//
//  Created by Calvin Lough on 4/6/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLDatabaseHelper.h"
#import "CLGoogleFeedOperation.h"
#import "CLSourceListFeed.h"
#import "CLPost.h"
#import "CLUrlFetcher.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "GTMNSString+HTML.h"
#import "JSONKit.h"

@implementation CLGoogleFeedOperation

@synthesize feed;
@synthesize dbNewestItemTimestamp;
@synthesize expectedNumberOfUnreadItems;
@synthesize _guidsAlreadyProcessed;

- (id)init {
	self = [super init];
	if (self != nil) {
		[self set_guidsAlreadyProcessed:[NSMutableSet set]];
	}
	return self;
}

- (void)dealloc {
	[feed release];
	[_guidsAlreadyProcessed release];
	
	[super dealloc];
}

- (id <CLGoogleFeedOperationDelegate>)delegate {
	return (id <CLGoogleFeedOperationDelegate>)[self _delegate];
}

- (void)setDelegate:(id <CLGoogleFeedOperationDelegate>)delegate {
	[self set_delegate:delegate];
}

- (void)main {
	
	@try {
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if (dbNewestItemTimestamp < 0) {
			dbNewestItemTimestamp = 0;
		}
		
		if (expectedNumberOfUnreadItems < 0) {
			expectedNumberOfUnreadItems = 0;
		}
		
		if (feed == nil) {
			[self completeOperation];
			[pool drain];
			return;
		}
		
		NSInteger numberOfUnreadItemsFound = 0;
		
		NSMutableArray *newPosts = [NSMutableArray array];
		NSMutableSet *dbUnreadGuids = [[feed googleUnreadGuids] mutableCopy];
		NSInteger newestItemTimestamp = dbNewestItemTimestamp;
		NSInteger originalDbNewestItemTimestamp = dbNewestItemTimestamp;
		NSInteger since = dbNewestItemTimestamp;
		
		NSData *postsData = nil;
		NSInteger statusCode = 0;
		
		// first, download all items that have arrived since the last sync
		postsData = [self fetch:GOOGLE_FETCH_SIZE itemsForUrlString:[feed googleUrl] since:since usingAuth:googleAuth statusCode:&statusCode];
		
		if ([CLUrlFetcher isSuccessStatusCode:statusCode] == NO || postsData == nil) {
			if ([self resetAuth] == NO) {
				[pool drain];
				return;
			}
			
			postsData = [self fetch:GOOGLE_FETCH_SIZE itemsForUrlString:[feed googleUrl] since:since usingAuth:googleAuth statusCode:&statusCode];
		}
		
		BOOL hasSyncedMetadata = NO;
		
		while (postsData != nil) {
			
			NSDictionary *postsDictionary = [postsData objectFromJSONDataWithParseOptions:JKParseOptionNone];
			postsData = nil; // prevent infinite loop
			
			if (postsDictionary != nil) {
				
				if (hasSyncedMetadata == NO) {
					[self updateMetaDataUsingDictionary:postsDictionary];
					hasSyncedMetadata = YES;
				}
				
				NSArray *items = [postsDictionary objectForKey:@"items"];
				
				NSInteger unreadItemsFound = [self processItems:items newPosts:newPosts dbUnreadGuids:dbUnreadGuids newestTimestamp:&newestItemTimestamp];
				numberOfUnreadItemsFound += unreadItemsFound;
				
				if (newestItemTimestamp > dbNewestItemTimestamp) {
					dbNewestItemTimestamp = newestItemTimestamp;
				}
				
				BOOL allUnreadDownloaded = (numberOfUnreadItemsFound >= expectedNumberOfUnreadItems);
				
				NSString *continuation = [postsDictionary objectForKey:@"continuation"];
				
				if (continuation != nil && [continuation isEqual:@""] == NO && allUnreadDownloaded == NO) {
					
					CLLog(@"1fetching more items for %@", [feed googleUrl]);
					postsData = [self fetch:GOOGLE_FETCH_SIZE itemsForUrlString:[feed googleUrl] since:since continuation:continuation usingAuth:googleAuth statusCode:&statusCode];
					
					if ([CLUrlFetcher isSuccessStatusCode:statusCode] == NO || postsData == nil) {
						if ([self resetAuth] == NO) {
							[pool drain];
							return;
						}
						
						postsData = [self fetch:GOOGLE_FETCH_SIZE itemsForUrlString:[feed googleUrl] since:since continuation:continuation usingAuth:googleAuth statusCode:&statusCode];
					}
				}
			}
		}
		
		// second, download all unread items
		NSMutableSet *feedUnreadGuids = [NSMutableSet set];
		NSInteger unreadItemsSince = [[NSDate date] timeIntervalSince1970] - (TIME_INTERVAL_DAY * 30);
		NSInteger unreadItemsProcessed = 0;
		
		postsData = [self fetch:GOOGLE_FETCH_SIZE unreadItemsForUrlString:[feed googleUrl] since:unreadItemsSince usingAuth:googleAuth statusCode:&statusCode];
		
		if ([CLUrlFetcher isSuccessStatusCode:statusCode] == NO || postsData == nil) {
			if ([self resetAuth] == NO) {
				[pool drain];
				return;
			}
			
			postsData = [self fetch:GOOGLE_FETCH_SIZE unreadItemsForUrlString:[feed googleUrl] since:unreadItemsSince usingAuth:googleAuth statusCode:&statusCode];
		}
		
		while (postsData != nil) {
			
			NSDictionary *postsDictionary = [postsData objectFromJSONDataWithParseOptions:JKParseOptionNone];
			postsData = nil; // this line is neccessary to prevent infinite loop
			
			if (postsDictionary != nil) {
				
				NSArray *items = [postsDictionary objectForKey:@"items"];
				
				NSInteger unreadProcessed = [self processUnreadItems:items unreadGuids:feedUnreadGuids];
				unreadItemsProcessed += unreadProcessed;
				
				BOOL allUnreadProcessed = (unreadItemsProcessed >= expectedNumberOfUnreadItems);
				
				NSString *continuation = [postsDictionary objectForKey:@"continuation"];
				
				if (continuation != nil && [continuation isEqual:@""] == NO && allUnreadProcessed == NO) {
					
					CLLog(@"2fetching more items for %@", [feed googleUrl]);
					postsData = [self fetch:GOOGLE_FETCH_SIZE unreadItemsForUrlString:[feed googleUrl] since:unreadItemsSince continuation:continuation usingAuth:googleAuth statusCode:&statusCode];
					
					if ([CLUrlFetcher isSuccessStatusCode:statusCode] == NO || postsData == nil) {
						if ([self resetAuth] == NO) {
							[pool drain];
							return;
						}
						
						postsData = [self fetch:GOOGLE_FETCH_SIZE unreadItemsForUrlString:[feed googleUrl] since:unreadItemsSince continuation:continuation usingAuth:googleAuth statusCode:&statusCode];
					}
				}
			}
		}
		
		// detect when items are read externally
		NSMutableSet *readExternallyGuids = [NSMutableSet set];
		
		for (NSNumber *dbUnreadGuid in dbUnreadGuids) {
			if ([feedUnreadGuids containsObject:dbUnreadGuid] == NO) {
				CLLog(@"%@ was read externally", dbUnreadGuid);
				[readExternallyGuids addObject:dbUnreadGuid];
			}
		}
		
		// detect when items that we think are read are actually unread
		NSMutableSet *unreadExternallyGuids = [NSMutableSet set];
		
		for (NSNumber *feedUnreadGuid in feedUnreadGuids) {
			CLLog(@"count: %ld contains %@", [dbUnreadGuids count], feedUnreadGuid);
			if ([dbUnreadGuids containsObject:feedUnreadGuid] == NO) {
				CLLog(@"%@ was marked unread externally", feedUnreadGuid);
				[unreadExternallyGuids addObject:feedUnreadGuid];
			}
		}
		
		if ([readExternallyGuids count] > 0 || [unreadExternallyGuids count] > 0) {
			NSMutableSet *readExternallyDbIds = [NSMutableSet set];
			NSMutableSet *unreadExternallyDbIds = [NSMutableSet set];
			
			FMDatabase *db = [FMDatabase databaseWithPath:[CLDatabaseHelper pathForDatabaseFile]];
			
			if (![db open]) {
				CLLog(@"failed to connect to database!");
				[self completeOperation];
				[pool drain];
				return;
			}
			
			for (NSString *readExternallyGuid in readExternallyGuids) {
				FMResultSet *rs = [db executeQuery:@"SELECT Id FROM post WHERE Guid=?", readExternallyGuid];
				
				CLLog(@"looking up db id for %@", readExternallyGuid);
				
				if ([rs next]) {
					CLLog(@"found %ld", [rs longForColumn:@"Id"]);
					[readExternallyDbIds addObject:[NSNumber numberWithInteger:[rs longForColumn:@"Id"]]];
				}
				
				[rs close];
			}
			
			for (NSString *unreadExternallyGuid in unreadExternallyGuids) {
				FMResultSet *rs = [db executeQuery:@"SELECT Id FROM post WHERE Guid=?", unreadExternallyGuid];
				
				CLLog(@"looking up db id for %@", unreadExternallyGuid);
				
				if ([rs next]) {
					CLLog(@"found %ld", [rs longForColumn:@"Id"]);
					[unreadExternallyDbIds addObject:[NSNumber numberWithInteger:[rs longForColumn:@"Id"]]];
				}
				
				[rs close];
			}
			
			[db close];
			
			for (NSNumber *readExternallyDbId in readExternallyDbIds) {
				[self performSelectorOnMainThread:@selector(dispatchPostReadDelegateMessage:) withObject:readExternallyDbId waitUntilDone:YES];
			}
			
			for (NSNumber *unreadExternallyDbId in unreadExternallyDbIds) {
				[self performSelectorOnMainThread:@selector(dispatchPostUnreadDelegateMessage:) withObject:unreadExternallyDbId waitUntilDone:YES];
			}
		}
		
		if (dbNewestItemTimestamp > originalDbNewestItemTimestamp) {
			[self updateDBWithNewestItemTimestamp:dbNewestItemTimestamp];
		}
		
		// process new stuff last
		// this needs to happen *after* the delegate messages are sent for dispatchPostRead and dispatchPostUnread
		if ([newPosts count] > 0) {
			NSInteger numberOfNewPosts = [newPosts count];
			NSInteger postsProcessed = 0;
			
			while (postsProcessed < numberOfNewPosts) {
				
				NSInteger postsRemaining = numberOfNewPosts - postsProcessed;
				NSInteger postsToProcess = PROCESS_NEW_POSTS_BATCH_SIZE;
				
				if (postsToProcess > postsRemaining) {
					postsToProcess = postsRemaining;
				}
				
				NSArray *currentPosts = [newPosts subarrayWithRange:NSMakeRange(postsRemaining - postsToProcess, postsToProcess)];
				
				[self performSelectorOnMainThread:@selector(dispatchNewPostsDelegateMessage:) withObject:currentPosts waitUntilDone:YES];
				
				postsProcessed += postsToProcess;
				
				if (postsProcessed < numberOfNewPosts) {
					[NSThread sleepForTimeInterval:PROCESS_NEW_POSTS_DELAY];
				}
			}
		}
		
		CLLog(@"done");
		
		[self completeOperation];
		[pool drain];
		
	} @catch(...) {
		// Do not rethrow exceptions.
	}
}

- (void)updateMetaDataUsingDictionary:(NSDictionary *)dictionary {
	
	// website link
	NSArray *alternate = [dictionary objectForKey:@"alternate"];
	NSString *hrefValue = nil;
	
	if (alternate != nil && [alternate count] > 0) {
		hrefValue = [[alternate objectAtIndex:0] objectForKey:@"href"];
	}
	
	if (hrefValue != nil && [hrefValue length] > 0) {
		if ([[feed websiteLink] isEqual:hrefValue] == NO) {
			[feed setWebsiteLink:hrefValue];
			
			FMDatabase *db = [FMDatabase databaseWithPath:[CLDatabaseHelper pathForDatabaseFile]];
			
			if (![db open]) {
				CLLog(@"failed to connect to database!");
				return;
			}
			
			[db executeUpdate:@"UPDATE feed SET WebsiteLink=? WHERE Id=?", hrefValue, [NSNumber numberWithInteger:[feed dbId]]];
			
			[db close];
			
			[self performSelectorOnMainThread:@selector(dispatchWebsiteLinkDelegateMessage) withObject:nil waitUntilDone:YES];
		}
	}
	
	// title
	NSString *title = [dictionary objectForKey:@"title"];
	
	if (title != nil && [title length] > 0) {
		
		// this title can be different from the title that the user has given the feed, so only use it
		// if we have just added this feed and the title is nil (google seems to have 2 titles for each feed, this 
		// one is less reliable)
		if ([feed title] == nil) {
			[feed setTitle:[title gtm_stringByUnescapingFromHTML]];
			[self performSelectorOnMainThread:@selector(dispatchTitleDelegateMessage) withObject:nil waitUntilDone:YES];
		}
	}
}

- (NSInteger)processItems:(NSArray *)items newPosts:(NSMutableArray *)newPosts dbUnreadGuids:(NSMutableSet *)dbUnreadGuids newestTimestamp:(NSInteger *)newestTimestamp {
	
	NSInteger unreadItemsFound = 0;
	
	FMDatabase *db = [FMDatabase databaseWithPath:[CLDatabaseHelper pathForDatabaseFile]];
	
	if (![db open]) {
		CLLog(@"failed to connect to database!");
		return 0;
	}
	
	for (NSDictionary *itemDict in items) {
		CLPost *post = [[CLPost alloc] initWithJSON:itemDict];
		
		if (([post title] != nil && [[post title] length] > 0) || ([post content] != nil && [[post content] length] > 0)) {
			
			BOOL postIsNew = YES;
			
			if ([_guidsAlreadyProcessed containsObject:[post guid]]) {
				
				postIsNew = NO;
				
			} else {
				
				FMResultSet *rs = [db executeQuery:@"SELECT * FROM post WHERE Guid=? AND FeedId=?", [post guid], [NSNumber numberWithInteger:[feed dbId]]];
				
				if ([db hadError] || [rs next]) {
					postIsNew = NO;
				}
				
				[rs close];
			}
			
			if (postIsNew) {
				[newPosts addObject:post];
				
				if ([post isRead] == NO) {
					[dbUnreadGuids addObject:[post guid]];
				}
			}
		}
		
		if ([post isRead] == NO) {
			unreadItemsFound++;
		}
		
		NSInteger itemTimestamp = (NSInteger)[[post published] timeIntervalSince1970];
		
		if (itemTimestamp > *newestTimestamp) {
			*newestTimestamp = itemTimestamp;
		}
		
		[_guidsAlreadyProcessed addObject:[post guid]];
		
		[post release];
	}
	
	[db close];
	
	return unreadItemsFound;
}

- (NSInteger)processUnreadItems:(NSArray *)items unreadGuids:(NSMutableSet *)unreadGuids {
	
	NSInteger unreadItemsFound = 0;
	
	for (NSDictionary *itemDict in items) {
		
		// even though we ask for only unread items, google will return read items too with the property isReadStateLocked set to true
		NSNumber *isReadStateLocked = [itemDict objectForKey:@"isReadStateLocked"];
		
		CLLog(@"unread: %@", [itemDict objectForKey:@"id"]);
		
		if (isReadStateLocked == nil || [isReadStateLocked boolValue] == NO) {
			CLLog(@"adding");
			[unreadGuids addObject:[itemDict objectForKey:@"id"]];
			unreadItemsFound++;
		}
	}
	
	return unreadItemsFound;
}

- (void)updateDBWithNewestItemTimestamp:(NSInteger)timestamp {
	FMDatabase *db = [FMDatabase databaseWithPath:[CLDatabaseHelper pathForDatabaseFile]];
	
	if (![db open]) {
		CLLog(@"failed to connect to database!");
		return;
	}
	
	[db executeUpdate:@"UPDATE feed SET GoogleNewestItemTimestamp=? WHERE Id=?", [NSNumber numberWithInteger:timestamp], [NSNumber numberWithInteger:[feed dbId]]];
	
	[db close];
}


- (void)dispatchPostReadDelegateMessage:(NSNumber *)dbId {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	[[self delegate] googleFeedOperation:self markPostWithDbIdAsRead:[dbId integerValue]];
}

- (void)dispatchPostUnreadDelegateMessage:(NSNumber *)dbId {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	[[self delegate] googleFeedOperation:self markPostWithDbIdAsUnread:[dbId integerValue]];
}

- (void)dispatchWebsiteLinkDelegateMessage {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	[[self delegate] googleFeedOperation:self foundWebsiteLinkForFeed:feed];
}

- (void)dispatchTitleDelegateMessage {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	[[self delegate] googleFeedOperation:self foundTitleForFeed:feed];
}

- (void)dispatchNewPostsDelegateMessage:(NSArray *)newPosts {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	[[self delegate] googleFeedOperation:self foundNewPosts:newPosts forFeed:feed];
}

@end
