//
//  CLGoogleStarredOperation.m
//  Syndication
//
//  Created by Calvin Lough on 6/14/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLDatabaseHelper.h"
#import "CLGoogleStarredOperation.h"
#import "CLPost.h"
#import "CLSourceListFeed.h"
#import "CLUrlFetcher.h"
#import "FMDatabase.h"
#import "JSONKit.h"

@implementation CLGoogleStarredOperation

- (id <CLGoogleStarredOperationDelegate>)delegate {
	return (id <CLGoogleStarredOperationDelegate>)[self _delegate];
}

- (void)setDelegate:(id <CLGoogleStarredOperationDelegate>)delegate {
	[self set_delegate:delegate];
}

- (void)main {
	
	@try {
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSInteger statusCode = 0;
		NSData *postsData = [self fetch:GOOGLE_FETCH_SIZE starredItemsUsingAuth:googleAuth statusCode:&statusCode];
		
		if ([CLUrlFetcher isSuccessStatusCode:statusCode] == NO  || postsData == nil) {
			if ([self resetAuth] == NO) {
				[pool drain];
				return;
			}
			
			postsData = [self fetch:GOOGLE_FETCH_SIZE starredItemsUsingAuth:googleAuth statusCode:&statusCode];
		}
		
		NSInteger numberOfFetches = 1;
		
		NSArray *dbStarredItems = [self getDbStarredItems];
		NSMutableArray *readerStarredItems = [NSMutableArray array];
		
		while (postsData != nil) {
			
			NSDictionary *postsDictionary = [postsData objectFromJSONDataWithParseOptions:JKParseOptionRecover];
			postsData = nil; // this line is neccessary to prevent infinite loop
			
			if (postsDictionary != nil) {
				
				NSArray *items = [postsDictionary objectForKey:@"items"];
				
				FMDatabase *db = [FMDatabase databaseWithPath:[CLDatabaseHelper pathForDatabaseFile]];
				
				if (![db open]) {
					CLLog(@"failed to connect to database!");
					[self completeOperation];
					[pool drain];
					return;
				}
				
				for (NSDictionary *itemDict in items) {
					CLPost *post = [[CLPost alloc] initWithJSON:itemDict];
					
					[post setIsRead:YES];
					
					NSDictionary *origin = [itemDict objectForKey:@"origin"];
					NSString *googleUrl = [origin objectForKey:@"streamId"];
					NSString *feedTitle = [origin objectForKey:@"title"];
					
					if (googleUrl != nil && [googleUrl length] > 0) {
						FMResultSet *rs = [db executeQuery:@"SELECT * FROM feed WHERE GoogleUrl=?", googleUrl];
						
						if ([rs next]) {
							[post setFeedDbId:[rs longForColumn:@"Id"]];
							[post setFeedTitle:[rs stringForColumn:@"Title"]];
						}
						
						[rs close];
						
						// if the next if statement passes, the user has a starred item from a feed that they aren't subscribed to
						if ([post feedDbId] <= 0) {
							[db executeUpdate:@"INSERT INTO feed (Title, IsFromGoogle, GoogleUrl, IsHidden) VALUES (?, 1, ?, 1)", feedTitle, googleUrl];
							
							[post setFeedDbId:[db lastInsertRowId]];
							[post setFeedTitle:feedTitle];
							
							
							rs = [db executeQuery:@"SELECT * FROM feed WHERE GoogleUrl=?, IsFromGoogle=1, IsHidden=1", googleUrl];
							
							if ([rs next]) {
								CLSourceListFeed *feed = [[CLSourceListFeed alloc] initWithResultSet:rs];
								[self performSelectorOnMainThread:@selector(dispatchDidAddHiddenFeedDelegateMessage:) withObject:feed waitUntilDone:YES];
								[feed release];
							}
							
							[rs close];
						}
					}
					
					if ((([post title] != nil && [[post title] length] > 0) || ([post content] != nil && [[post content] length] > 0)) && [post feedDbId] > 0) {
						[readerStarredItems addObject:post];
					}
					
					[post release];
				}
				
				[db close];
				
				NSString *continuation = [postsDictionary objectForKey:@"continuation"];
				NSInteger fetchLimit = 5;
				
				if (continuation != nil && [continuation isEqual:@""] == NO && numberOfFetches < fetchLimit) {
					
					postsData = [self fetch:GOOGLE_FETCH_SIZE starredItemsUsingAuth:googleAuth continuation:continuation statusCode:&statusCode];
					
					if ([CLUrlFetcher isSuccessStatusCode:statusCode] == NO  || postsData == nil) {
						if ([self resetAuth] == NO) {
							[pool drain];
							return;
						}
						
						postsData = [self fetch:GOOGLE_FETCH_SIZE starredItemsUsingAuth:googleAuth continuation:continuation statusCode:&statusCode];
					}
					
					numberOfFetches++;
				}
			}
		}
		
		NSMutableArray *toAdd = [NSMutableArray array];
		NSMutableArray *toRemove = [NSMutableArray array];
		
		for (CLPost *readerPost in readerStarredItems) {
			BOOL existsInDb = NO;
			
			for (CLPost *dbPost in dbStarredItems) {
				if ([[dbPost guid] isEqual:[readerPost guid]]) {
					existsInDb = YES;
				}
			}
			
			if (existsInDb == NO) {
				[toAdd addObject:readerPost];
			}
		}
		
		NSInteger numberOfNewPosts = [toAdd count];
		NSInteger postsProcessed = 0;
		
		while (postsProcessed < numberOfNewPosts) {
			
			NSInteger postsRemaining = numberOfNewPosts - postsProcessed;
			NSInteger postsToProcess = PROCESS_NEW_POSTS_BATCH_SIZE;
			
			if (postsToProcess > postsRemaining) {
				postsToProcess = postsRemaining;
			}
			
			NSArray *currentPosts = [[[toAdd subarrayWithRange:NSMakeRange(postsRemaining - postsToProcess, postsToProcess)] reverseObjectEnumerator] allObjects];
			
			[self performSelectorOnMainThread:@selector(dispatchAddItemsDelegateMessage:) withObject:currentPosts waitUntilDone:YES];
			
			postsProcessed += postsToProcess;
			
			if (postsProcessed < numberOfNewPosts) {
				[NSThread sleepForTimeInterval:PROCESS_NEW_POSTS_DELAY];
			}
		}
		
		for (CLPost *dbPost in dbStarredItems) {
			BOOL existsInReader = NO;
			
			for (CLPost *readerPost in readerStarredItems) {
				if ([[dbPost guid] isEqual:[readerPost guid]]) {
					existsInReader = YES;
				}
			}
			
			if (existsInReader == NO) {
				[toRemove addObject:dbPost];
			}
		}
		
		if ([toRemove count] > 0) {
			[self performSelectorOnMainThread:@selector(dispatchRemoveItemsDelegateMessage:) withObject:toRemove waitUntilDone:YES];
		}
		
		[self completeOperation];
		[pool drain];
		
	} @catch(...) {
		// Do not rethrow exceptions.
	}
}

- (NSArray *)getDbStarredItems {
	NSMutableArray *starredItems = [NSMutableArray array];
	
	FMDatabase *db = [FMDatabase databaseWithPath:[CLDatabaseHelper pathForDatabaseFile]];
	
	if (![db open]) {
		CLLog(@"failed to connect to database!");
		return nil;
	}
	
	FMResultSet *rs = [db executeQuery:@"SELECT post.*, feed.Title AS FeedTitle, feed.Url AS FeedUrlString FROM post, feed WHERE post.FeedId=feed.Id AND feed.IsFromGoogle=1 AND post.IsStarred=1"];
	
	while ([rs next]) {
		CLPost *post = [[CLPost alloc] initWithResultSet:rs];
		[starredItems addObject:post];
		[post release];
	}
	
	[rs close];
	[db close];
	
	return starredItems;
}

- (void)dispatchAddItemsDelegateMessage:(NSArray *)items {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	[[self delegate] googleStarredOperation:self addStarredItems:items];
}

- (void)dispatchRemoveItemsDelegateMessage:(NSArray *)items {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	[[self delegate] googleStarredOperation:self removeStarredItems:items];
}

- (void)dispatchDidAddHiddenFeedDelegateMessage:(CLSourceListFeed *)feed {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	[[self delegate] googleStarredOperation:self didAddNewHiddenFeed:feed];
}

@end
