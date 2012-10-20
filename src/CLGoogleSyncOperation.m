//
//  CLGoogleSyncOperation.m
//  Syndication
//
//  Created by Calvin Lough on 3/29/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLDatabaseHelper.h"
#import "CLGoogleSyncOperation.h"
#import "CLPost.h"
#import "CLSourceListFeed.h"
#import "CLUrlFetcher.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "GTMNSString+HTML.h"
#import "JSONKit.h"
#import "NSString+CLAdditions.h"

@implementation CLGoogleSyncOperation

- (id <CLGoogleSyncOperationDelegate>)delegate {
	return (id <CLGoogleSyncOperationDelegate>)[self _delegate];
}

- (void)setDelegate:(id <CLGoogleSyncOperationDelegate>)delegate {
	[self set_delegate:delegate];
}

- (void)main {
	
	@try {
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSInteger statusCode = 0;
		NSData *feedData = [self fetchFeedListUsingAuth:googleAuth statusCode:&statusCode];
		
		if ([CLUrlFetcher isSuccessStatusCode:statusCode] == NO  || feedData == nil) {
			if ([self resetAuth] == NO) {
				[pool drain];
				return;
			}
			
			feedData = [self fetchFeedListUsingAuth:googleAuth statusCode:&statusCode];
		}
		
		if ([CLUrlFetcher isSuccessStatusCode:statusCode] && feedData != nil) {
			NSDictionary *feedDictionary = [feedData objectFromJSONDataWithParseOptions:JKParseOptionNone];
			
			if (feedDictionary != nil) {
				NSArray *subscriptions = [feedDictionary objectForKey:@"subscriptions"];
				NSMutableArray *readerFeedList = [NSMutableArray array];
				NSMutableArray *dbFeedList = [NSMutableArray array];
				
				if (subscriptions != nil) {
					
					NSMutableDictionary *dbTitleDictionary = [NSMutableDictionary dictionary];
					
					[self dbPopulateFeedList:&dbFeedList titleDictionary:&dbTitleDictionary newestItemDictionary:nil];
					
					NSMutableDictionary *readerTitleDictionary = [NSMutableDictionary dictionary];
					NSMutableDictionary *readerFolderDictionary = [NSMutableDictionary dictionary];
					
					for (NSDictionary *subscription in subscriptions) {
						NSString *feedurl = [[subscription objectForKey:@"id"] clTrimmedString];
						[readerFeedList addObject:feedurl];
						[readerTitleDictionary setValue:[subscription objectForKey:@"title"] forKey:feedurl];
						
						NSArray *categories = [subscription objectForKey:@"categories"];
						
						if ([categories count] > 0) {
							NSString *folder = [[categories objectAtIndex:0] objectForKey:@"label"];
							[readerFolderDictionary setValue:folder forKey:feedurl];
						}
					}
					
					[NSThread sleepForTimeInterval:GOOGLE_REQUEST_PAUSE]; // give google's servers a break between requests
					
					NSData *unreadData = [self fetchUnreadCountsUsingAuth:googleAuth statusCode:&statusCode];
					
					if ([CLUrlFetcher isSuccessStatusCode:statusCode] == NO || unreadData == nil) {
						if ([self resetAuth] == NO) {
							[pool drain];
							return;
						}
						
						unreadData = [self fetchUnreadCountsUsingAuth:googleAuth statusCode:&statusCode];
					}
					
					NSMutableDictionary *feedUnreadCountDictionary = [NSMutableDictionary dictionary];
					
					if (unreadData != nil) {
						NSDictionary *unreadDictionary = [unreadData objectFromJSONDataWithParseOptions:JKParseOptionNone];
						
						if (unreadDictionary != nil) {
							NSArray *unreadSubscriptions = [unreadDictionary objectForKey:@"unreadcounts"];
							
							if (unreadSubscriptions != nil) {
								for (NSDictionary *unreadSubscription in unreadSubscriptions) {
									NSString *feedUrl = [[unreadSubscription objectForKey:@"id"] clTrimmedString];
									
									if (feedUrl != nil) {
										NSString *feedUnreadCount = [unreadSubscription objectForKey:@"count"];
										
										if (feedUnreadCount != nil) {
											[feedUnreadCountDictionary setValue:feedUnreadCount forKey:feedUrl];
										}
									}
								}
							}
						}
					}
					
					for (NSString *dbFeed in dbFeedList) {
						
						// delete feeds that we have in our database but have been deleted in google reader
						if ([readerFeedList containsObject:dbFeed] == NO) {
							[self performSelectorOnMainThread:@selector(dispatchDeleteFeedDelegateMessage:) withObject:dbFeed waitUntilDone:YES];
						}
					}
					
					for (NSString *readerFeed in readerFeedList) {
						
						// add feeds that we don't have in our database but have been added to google reader
						if ([dbFeedList containsObject:readerFeed] == NO) {
							NSString *title = [readerTitleDictionary objectForKey:readerFeed];
							NSString *folder = [readerFolderDictionary objectForKey:readerFeed];
							
							NSMutableDictionary *params = [NSMutableDictionary dictionary];
							[params setValue:title forKey:@"title"];
							[params setValue:readerFeed forKey:@"urlString"];
							[params setValue:folder forKey:@"folderTitle"];
							
							[self performSelectorOnMainThread:@selector(dispatchAddFeedDelegateMessage:) withObject:params waitUntilDone:YES];
						}
					}
					
					// update titles
					for (NSString *readerFeed in readerFeedList) {
						
						NSString *title = [readerTitleDictionary objectForKey:readerFeed];
						NSString *dbTitle = [dbTitleDictionary objectForKey:readerFeed];
						
						if (title != nil) {
							title = [title gtm_stringByUnescapingFromHTML];
						}
						
						if (title != nil && (dbTitle == nil || [title isEqual:dbTitle] == NO)) {
							CLLog(@"changing title for %@ to %@", readerFeed, title);
							
							NSMutableDictionary *params = [NSMutableDictionary dictionary];
							[params setValue:title forKey:@"title"];
							[params setValue:readerFeed forKey:@"urlString"];
							
							[self performSelectorOnMainThread:@selector(dispatchFoundTitleDelegateMessage:) withObject:params waitUntilDone:YES];
						}
					}
					
					// update folders
					for (NSString *readerFeed in readerFeedList) {
						NSString *folder = [readerFolderDictionary objectForKey:readerFeed];
						
						NSMutableDictionary *params = [NSMutableDictionary dictionary];
						[params setValue:readerFeed forKey:@"urlString"];
						[params setValue:folder forKey:@"folderTitle"];
						
						[self performSelectorOnMainThread:@selector(dispatchFoundFolderDelegateMessage:) withObject:params waitUntilDone:YES];
					}
					
					NSMutableDictionary *dbNewestItemDictionary = [NSMutableDictionary dictionary];
					[self dbPopulateFeedList:&dbFeedList titleDictionary:nil newestItemDictionary:&dbNewestItemDictionary];
					
					for (NSString *feedUrlString in dbFeedList) {
						
						NSInteger dbNewestItemTimestamp = 0;
						
						if ([dbNewestItemDictionary objectForKey:feedUrlString] != nil) {
							dbNewestItemTimestamp = [[dbNewestItemDictionary objectForKey:feedUrlString] integerValue];
						}
						
						NSInteger feedUnreadCount = 0;
						
						if ([feedUnreadCountDictionary objectForKey:feedUrlString] != nil) {
							feedUnreadCount = [[feedUnreadCountDictionary objectForKey:feedUrlString] integerValue];
						}
						
						CLLog(@"queueing %@", feedUrlString);
						
						NSMutableDictionary *params = [NSMutableDictionary dictionary];
						[params setValue:feedUrlString forKey:@"urlString"];
						[params setValue:[NSNumber numberWithInteger:dbNewestItemTimestamp] forKey:@"timestamp"];
						[params setValue:[NSNumber numberWithInteger:feedUnreadCount] forKey:@"unreadCount"];
						
						[self performSelectorOnMainThread:@selector(dispatchQueueFeedDelegateMessage:) withObject:params waitUntilDone:YES];
					}
				}
			}
		}
		
		[self completeOperation];
		[pool drain];
		
	} @catch(...) {
		// Do not rethrow exceptions.
	}
}

- (void)dbPopulateFeedList:(NSMutableArray **)feedListPtr titleDictionary:(NSMutableDictionary **)titleDictPtr newestItemDictionary:(NSMutableDictionary **)newestItemDictPtr {
	
	NSMutableArray *feedList = nil;
	NSMutableDictionary *titleDict = nil;
	NSMutableDictionary *newestItemDict = nil;
	
	if (feedListPtr != nil) {
		feedList = *feedListPtr;
		[feedList removeAllObjects];
	}
	
	if (titleDictPtr != nil) {
		titleDict = *titleDictPtr;
		[titleDict removeAllObjects];
	}
	
	if (newestItemDictPtr != nil) {
		newestItemDict = *newestItemDictPtr;
		[newestItemDict removeAllObjects];
	}
	
	FMDatabase *db = [FMDatabase databaseWithPath:[CLDatabaseHelper pathForDatabaseFile]];
	
	if (![db open]) {
		CLLog(@"failed to connect to database!");
		return;
	}
	
	FMResultSet *rs = [db executeQuery:@"SELECT * FROM feed WHERE IsFromGoogle=1 AND IsHidden=0"];
	
	while ([rs next]) {
		NSString *dbUrl = [rs stringForColumn:@"GoogleUrl"];
		
		if (feedList != nil) {
			[feedList addObject:dbUrl];
		}
		
		if (titleDict != nil) {
			[titleDict setValue:[rs stringForColumn:@"Title"] forKey:dbUrl];
		}
		
		if (newestItemDict != nil) {
			[newestItemDict setValue:[NSNumber numberWithInteger:[rs longForColumn:@"GoogleNewestItemTimestamp"]] forKey:dbUrl];
		}
	}
	
	[rs close];
	[db close];
}

- (void)dispatchDeleteFeedDelegateMessage:(NSString *)urlString {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	[[self delegate] googleSyncOperation:self deleteFeedWithUrlString:urlString];
}

- (void)dispatchAddFeedDelegateMessage:(NSDictionary *)params {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	NSString *urlString = [params objectForKey:@"urlString"];
	NSString *title = [params objectForKey:@"title"];
	NSString *folderTitle = [params objectForKey:@"folderTitle"];
	
	[[self delegate] googleSyncOperation:self addFeedWithUrlString:urlString title:title folderTitle:folderTitle];
}

- (void)dispatchFoundTitleDelegateMessage:(NSDictionary *)params {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	NSString *title = [params objectForKey:@"title"];
	NSString *urlString = [params objectForKey:@"urlString"];
	
	[[self delegate] googleSyncOperation:self foundTitle:title forUrlString:urlString];
}

- (void)dispatchFoundFolderDelegateMessage:(NSDictionary *)params {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	NSString *folder = [params objectForKey:@"folderTitle"];
	NSString *urlString = [params objectForKey:@"urlString"];
	
	[[self delegate] googleSyncOperation:self foundFolder:folder forUrlString:urlString];
}

- (void)dispatchQueueFeedDelegateMessage:(NSDictionary *)params {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	NSString *urlString = [params objectForKey:@"urlString"];
	NSInteger timestamp = [[params objectForKey:@"timestamp"] integerValue];
	NSInteger unreadCount = [[params objectForKey:@"unreadCount"] integerValue];
	
	[[self delegate] googleSyncOperation:self queueFeedOperationForUrlString:urlString newestItemTimestamp:timestamp unreadCount:unreadCount];
}

@end
