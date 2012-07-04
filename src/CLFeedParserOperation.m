//
//  CLFeedParserOperation.m
//  Syndication
//
//  Created by Calvin Lough on 6/23/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLDatabaseHelper.h"
#import "CLDateHelper.h"
#import "CLFeedParserOperation.h"
#import "CLHTMLFilter.h"
#import "CLPost.h"
#import "CLSourceListFeed.h"
#import "CLStringHelper.h"
#import "CLXMLNode.h"
#import "CLXMLParser.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "GTMNSString+HTML.h"

#define FEED_TYPE_UNKNOWN 0
#define FEED_TYPE_RSS 1
#define FEED_TYPE_ATOM 2

@implementation CLFeedParserOperation

@synthesize delegate;
@synthesize feed;
@synthesize data;
@synthesize encoding;
@synthesize allPosts;
@synthesize _atomFeedAuthor;
@synthesize _feedType;

- (id)init {
	self = [super init];
	if (self != nil) {
		[self setAllPosts:[NSMutableArray array]];
	}
	return self;
}

- (void)dealloc {
	[feed release];
	[data release];
	[allPosts release];
	[_atomFeedAuthor release];
	
	[super dealloc];
}

- (void)main {
	
	@try {
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		[self performSelectorOnMainThread:@selector(dispatchDidStartDelegateMessage) withObject:nil waitUntilDone:YES];
		
		if (feed == nil || data == nil) {
			CLLog(@"missing parse data");
			[self performSelectorOnMainThread:@selector(dispatchDidFinishDelegateMessage) withObject:nil waitUntilDone:YES];
			[pool drain];
			return;
		}
		
		BOOL isFirstSync = NO;
		
		if ([feed lastSyncPosts] == nil) {
			CLLog(@"first sync for %@", [feed extractTitleForDisplay]);
			isFirstSync = YES;
		}
		
		NSString *xmlString = [CLStringHelper stringFromData:data withPossibleEncoding:encoding];
		
		if (xmlString == nil || [xmlString length] == 0) {
			[self performSelectorOnMainThread:@selector(dispatchDidFinishDelegateMessage) withObject:nil waitUntilDone:YES];
			[pool drain];
			return;
		}
		
		CLXMLNode *rootNode = [CLXMLParser parseString:xmlString];
		
		if (rootNode == nil) {
			[self performSelectorOnMainThread:@selector(dispatchDidFinishDelegateMessage) withObject:nil waitUntilDone:YES];
			[pool drain];
			return;
		}
		
		[self processNode:rootNode];
		
		if ([allPosts count] > 0) {
			
			NSMutableArray *probablyNewPosts = nil;
			
			if (isFirstSync || [[feed lastSyncPosts] count] == 0) {
				probablyNewPosts = allPosts;
			} else {
				probablyNewPosts = [NSMutableArray array];
				
				for (CLPost *post in allPosts) {
					BOOL postIsProbablyNew = YES;
					
					NSString *postGuid = [post guid];
					NSString *postTitle = [post title];
					NSString *postPlainTextContent = [post plainTextContent];
					
					for (NSDictionary *lastSyncPost in [feed lastSyncPosts]) {
						
                        BOOL guidIsEqual = NO;
                        BOOL titleBothNil = NO;
                        BOOL titleIsEqual = NO;
                        BOOL contentBothNil = NO;
                        BOOL contentIsEqual = NO;
                        
                        NSString *syncPostGuid = [lastSyncPost objectForKey:@"guid"];
                        NSString *syncPostTitle = [lastSyncPost objectForKey:@"title"];
                        NSString *syncPostPlainTextContent = [lastSyncPost objectForKey:@"plainTextContent"];
                        
                        if (postGuid != nil && syncPostGuid != nil) {
							if ([postGuid isEqual:syncPostGuid]) {
								guidIsEqual = YES;
							}
						}
                        
                        if (postTitle == nil && syncPostTitle == nil) {
                            titleBothNil = YES;
                        } else if (postTitle != nil && syncPostTitle != nil) {
                            if ([postTitle isEqual:syncPostTitle]) {
                                titleIsEqual = YES;
                            }
                        }
                        
                        if (postPlainTextContent == nil && syncPostPlainTextContent == nil) {
                            contentBothNil = YES;
                        } else if (postPlainTextContent != nil && syncPostPlainTextContent != nil) {
                            if ([postPlainTextContent isEqual:syncPostPlainTextContent]) {
                                contentIsEqual = YES;
                            }
                        }
                        
                        if (guidIsEqual || ((titleIsEqual && contentIsEqual) || (titleIsEqual && contentBothNil) || (titleBothNil && contentIsEqual))) {
                            postIsProbablyNew = NO;
                            break;
                        }
					}
					
					if (postIsProbablyNew) {
						[probablyNewPosts addObject:post];
					}
				}
			}
			
			NSMutableArray *newPosts = nil;
			
			if (isFirstSync) {
				newPosts = probablyNewPosts;
			} else {
				newPosts = [NSMutableArray array];
				
				if ([probablyNewPosts count] > 0) {
						 
					FMDatabase *db = [FMDatabase databaseWithPath:[CLDatabaseHelper pathForDatabaseFile]];
					
					if (![db open]) {
						CLLog(@"failed to connect to database!");
						[self performSelectorOnMainThread:@selector(dispatchDidFinishDelegateMessage) withObject:nil waitUntilDone:YES];
						[pool drain];
						return;
					}
					
					for (CLPost *post in probablyNewPosts) {
						BOOL postIsNew = YES;
						
						FMResultSet *rs = nil;
                        
                        if ([post title] != nil && [[post title] length] > 0 && [post plainTextContent] != nil && [[post plainTextContent] length] > 0) {
                            rs = [db executeQuery:@"SELECT * FROM post WHERE FeedId=? AND Title=? AND PlainTextContent=?", [NSNumber numberWithInteger:[post feedDbId]], [post title], [post plainTextContent]];
                            
                            if ([db hadError] || [rs next]) {
                                postIsNew = NO;
                            }
                            
                            [rs close];
                        } else if ([post title] != nil && [[post title] length] > 0 && ([post plainTextContent] == nil || [[post plainTextContent] length] == 0)) {
                            rs = [db executeQuery:@"SELECT * FROM post WHERE FeedId=? AND Title=? AND PlainTextContent IS NULL", [NSNumber numberWithInteger:[post feedDbId]], [post title]];
                            
                            if ([db hadError] || [rs next]) {
                                postIsNew = NO;
                            }
                            
                            [rs close];
                        } else if ([post plainTextContent] != nil && [[post plainTextContent] length] > 0 && ([post title] == nil || [[post title] length] == 0)) {
                            rs = [db executeQuery:@"SELECT * FROM post WHERE FeedId=? AND Title IS NULL AND PlainTextContent=?", [NSNumber numberWithInteger:[post feedDbId]], [post plainTextContent]];
                            
                            if ([db hadError] || [rs next]) {
                                postIsNew = NO;
                            }
                            
                            [rs close];
                        }
                        
						// if we still think this post is new, check the guid
                        if (postIsNew && [post guid] != nil && [[post guid] length] > 0) {
							rs = [db executeQuery:@"SELECT * FROM post WHERE FeedId=? AND Guid=?", [NSNumber numberWithInteger:[post feedDbId]], [post guid]];
                            
                            if ([db hadError] || [rs next]) {
                                postIsNew = NO;
                            }
                            
                            [rs close];
                        }
						
						if (postIsNew) {
							[newPosts addObject:post];
						} else {
							CLLog(@"false positive, probably new post that wasn't actually new");
						}
					}
					
					[db close];
				}
			}
			
			if ([newPosts count] > 0) {
				
				// for first sync, only mark limited number of new items as unread
				if (isFirstSync) {
					
					NSInteger postCount = 0;
					
					for (CLPost *post in newPosts) {
						if (postCount >= 5) {
							[post setIsRead:YES];
						}
						
						NSTimeInterval timeSincePublished = [[NSDate date] timeIntervalSinceDate:[post published]];
						
						if (timeSincePublished > TIME_INTERVAL_MONTH) {
							[post setIsRead:YES];
						}
						
						postCount++;
					}
				}
				
				[feed setPostsToAddToDB:newPosts];
				
				CLLog(@"found %qu new posts for %@", [newPosts count], [feed extractTitleForDisplay]);
				
				[self performSelectorOnMainThread:@selector(dispatchNewPostsDelegateMessage) withObject:nil waitUntilDone:YES];
			}
		}
		
		[feed setPostsToAddToDB:nil];
		
		NSMutableArray *syncPosts = [NSMutableArray array];
		BOOL postsDidChange = NO;
		NSUInteger i = 0;
		
		for (CLPost *post in allPosts) {
			NSMutableDictionary *syncPost = [NSMutableDictionary dictionary];
			
			if ([post guid] != nil) {
				[syncPost setValue:[post guid] forKey:@"guid"];
			} else {
				[syncPost setValue:[post title] forKey:@"title"];
				[syncPost setValue:[post plainTextContent] forKey:@"plainTextContent"];
			}
			
			[syncPosts addObject:syncPost];
			
			if (postsDidChange == NO) {
				if ([feed lastSyncPosts] != nil && i < [[feed lastSyncPosts] count]) {
					NSMutableDictionary *lastSyncPost = [[feed lastSyncPosts] objectAtIndex:i];
					
					NSString *syncPostGuid = [syncPost objectForKey:@"guid"];
					NSString *syncPostTitle = [syncPost objectForKey:@"title"];
					NSString *syncPostPlainTextContent = [syncPost objectForKey:@"plainTextContent"];
					NSString *lastSyncPostGuid = [lastSyncPost objectForKey:@"guid"];
					NSString *lastSyncPostTitle = [lastSyncPost objectForKey:@"title"];
					NSString *lastSyncPostPlainTextContent = [lastSyncPost objectForKey:@"plainTextContent"];
					
					if ((syncPostGuid == nil && lastSyncPostGuid != nil) || (syncPostGuid != nil && lastSyncPostGuid == nil) || (syncPostGuid != nil && lastSyncPostGuid != nil && [syncPostGuid isEqual:lastSyncPostGuid] == NO)) {
						postsDidChange = YES;
					}
					
					if ((syncPostTitle == nil && lastSyncPostTitle != nil) || (syncPostTitle != nil && lastSyncPostTitle == nil) || (syncPostTitle != nil && lastSyncPostTitle != nil && [syncPostTitle isEqual:lastSyncPostTitle] == NO)) {
						postsDidChange = YES;
					}
					
					if ((syncPostPlainTextContent == nil && lastSyncPostPlainTextContent != nil) || (syncPostPlainTextContent != nil && lastSyncPostPlainTextContent == nil) || (syncPostPlainTextContent != nil && lastSyncPostPlainTextContent != nil && [syncPostPlainTextContent isEqual:lastSyncPostPlainTextContent] == NO)) {
						postsDidChange = YES;
					}
				}
			}
			
			i++;
		}
		
		if ([feed lastSyncPosts] == nil || [[feed lastSyncPosts] count] != [syncPosts count]) {
			postsDidChange = YES;
		}
		
		if (postsDidChange) {
			CLLog(@"posts did change for %@", [feed extractTitleForDisplay]);
			[feed setLastSyncPosts:syncPosts];
			
			FMDatabase *db = [FMDatabase databaseWithPath:[CLDatabaseHelper pathForDatabaseFile]];
			
			if (![db open]) {
				CLLog(@"failed to connect to database!");
				[self performSelectorOnMainThread:@selector(dispatchDidFinishDelegateMessage) withObject:nil waitUntilDone:YES];
				[pool drain];
				return;
			}
			
			NSData *syncPostsData = [NSArchiver archivedDataWithRootObject:syncPosts];
			[db executeUpdate:@"UPDATE feed SET LastSyncPosts=? WHERE Id=?", syncPostsData, [NSNumber numberWithInteger:[feed dbId]]];
			
			[db close];
		}
		
		CLLog(@"end of parsing for %@", [feed extractTitleForDisplay]);
		
		[self performSelectorOnMainThread:@selector(dispatchDidFinishDelegateMessage) withObject:nil waitUntilDone:YES];
		
		[pool drain];
		
	} @catch(...) {
		// Do not rethrow exceptions.
	}
}

- (void)processNode:(CLXMLNode *)node {
	BOOL shouldProcessChildren = YES;
	NSString *elementName = [[node name] lowercaseString];
	NSString *elementNameSpace = [[node nameSpace] lowercaseString];
	
	// figure out what type of feed this is
	if (_feedType == FEED_TYPE_UNKNOWN) {
		
		if ([elementName isEqual:@"rss"] || ([elementNameSpace isEqual:@"rdf"] && [elementName isEqual:@"rdf"])) {
			[self set_feedType:FEED_TYPE_RSS];
		} else if ([elementName isEqual:@"feed"]) {
			[self set_feedType:FEED_TYPE_ATOM];
		}
	}
	
	if ([elementName isEqual:@"title"]) {
		if ([feed title] == nil) {
			NSString *newTitle = [[node combinedTextValue] gtm_stringByUnescapingFromHTML];
			
			if ([newTitle length] > 0) {
				[feed setTitle:newTitle];
				[self performSelectorOnMainThread:@selector(dispatchTitleDelegateMessage) withObject:nil waitUntilDone:YES];
			}
		}
		
		shouldProcessChildren = NO;
	}
	
	if ([elementName isEqual:@"image"]) {
		shouldProcessChildren = NO;
	}
	
	if (_feedType == FEED_TYPE_ATOM) {
		if ([elementName isEqual:@"author"]) {
			for (CLXMLNode *childNode in [node children]) {
				NSString *childElementName = [childNode name];
				
				if ([childElementName isEqual:@"name"]) {
					[self set_atomFeedAuthor:[[childNode combinedTextValue] gtm_stringByUnescapingFromHTML]];
				}
			}
			
			shouldProcessChildren = NO;
		}
	}
	
	if (_feedType == FEED_TYPE_RSS) {
		
		if ([elementName isEqual:@"link"] && (elementNameSpace == nil || [elementNameSpace isEqual:@""])) {
			NSString *hrefValue = [node combinedTextValue];
			
			if ([[feed websiteLink] isEqual:hrefValue] == NO) {
				[feed setWebsiteLink:hrefValue];
				
				FMDatabase *db = [FMDatabase databaseWithPath:[CLDatabaseHelper pathForDatabaseFile]];
				
				if (![db open]) {
					CLLog(@"failed to connect to database!");
					db = nil;
				}
				
				[db executeUpdate:@"UPDATE feed SET WebsiteLink=? WHERE Id=?", hrefValue, [NSNumber numberWithInteger:[feed dbId]]];
				
				[db close];
				
				[self performSelectorOnMainThread:@selector(dispatchWebsiteLinkDelegateMessage) withObject:nil waitUntilDone:YES];
			}
			
			shouldProcessChildren = NO;
		}
		
		if ([elementName isEqual:@"item"]) {
			CLPost *newPost = [[CLPost alloc] init];
			[newPost setFeedDbId:[feed dbId]];
			[newPost setFeedTitle:[feed title]];
			[newPost setFeedUrlString:[feed url]];
			
			for (CLXMLNode *childNode in [node children]) {
				NSString *childElementName = [childNode name];
				NSString *childElementNameSpace = [childNode nameSpace];
				NSString *childValue = [childNode combinedTextValue];
				
				if ([childElementName isEqual:@"guid"]) {
					[newPost setGuid:childValue];
				}
				
				if ([childElementName isEqual:@"title"]) {
					[newPost setTitle:[childValue gtm_stringByUnescapingFromHTML]];
				}
				
				if ([childElementName isEqual:@"link"]) {
					[newPost setLink:childValue];
				}
				
				if ([childElementName isEqual:@"pubDate"]) {
					NSDate *parsedDate = [CLDateHelper dateFromInternetDateTimeString:childValue formatHint:CLDateFormatHintRFC822];
					if (parsedDate) {
						[newPost setPublished:parsedDate];
					}
				}
				
				if ([childElementNameSpace isEqual:@"dc"] && [childElementName isEqual:@"date"]) {
					NSDate *parsedDate = [CLDateHelper dateFromInternetDateTimeString:childValue formatHint:CLDateFormatHintRFC3339];
					if (parsedDate) {
						[newPost setPublished:parsedDate];
					}
				}
				
				if ([childElementName isEqual:@"author"]) {
					
					// only use this for the author if we don't have anything better
					if ([newPost author] == nil) {
						[newPost setAuthor:[childValue gtm_stringByUnescapingFromHTML]];
					}
				}
				
				if ([childElementNameSpace isEqual:@"dc"] && [childElementName isEqual:@"creator"]) {
					[newPost setAuthor:[childValue gtm_stringByUnescapingFromHTML]];
				}
				
				if ([childElementName isEqual:@"description"] || [childElementName isEqual:@"summary"]) {
					
					// only use this for the content if we don't have anything better
					if ([newPost content] == nil) {
						[newPost setContent:childValue];
					}
				}
				
				if ([childElementNameSpace isEqual:@"content"] && [childElementName isEqual:@"encoded"]) {
					[newPost setContent:childValue];
				}
				
				if ([childElementName isEqual:@"enclosure"]) {
					[[newPost enclosures] addObject:[[childNode attributes] objectForKey:@"url"]];
				}
			}
			
			if (([newPost title] != nil && [[newPost title] length] > 0) || ([newPost content] != nil && [[newPost content] length] > 0)) {
				
				if ([newPost content] != nil) {
					[newPost setPlainTextContent:[CLHTMLFilter extractPlainTextFromString:[newPost content]]];
				}
				
				[allPosts addObject:newPost];
			}
			
			[newPost release];
			
			shouldProcessChildren = NO;
		}
	} else if (_feedType == FEED_TYPE_ATOM) {
		
		if ([elementName isEqual:@"link"] && (elementNameSpace == nil || [elementNameSpace isEqual:@""])) {
			NSString *hrefValue = [[node attributes] objectForKey:@"href"];
			NSString *relValue = [[node attributes] objectForKey:@"rel"];
			
			if (relValue == nil || [relValue isEqual:@"alternate"]) {
				if ([[feed websiteLink] isEqual:hrefValue] == NO) {
					[feed setWebsiteLink:hrefValue];
					
					FMDatabase *db = [FMDatabase databaseWithPath:[CLDatabaseHelper pathForDatabaseFile]];
					
					if (![db open]) {
						CLLog(@"failed to connect to database!");
						db = nil;
					}
					
					[db executeUpdate:@"UPDATE feed SET WebsiteLink=? WHERE Id=?", hrefValue, [NSNumber numberWithInteger:[feed dbId]]];
					[db close];
					
					[self performSelectorOnMainThread:@selector(dispatchWebsiteLinkDelegateMessage) withObject:nil waitUntilDone:YES];
				}
			}
			
			shouldProcessChildren = NO;
		}
		
		if ([elementName isEqual:@"entry"]) {
			
			CLPost *newPost = [[CLPost alloc] init];
			[newPost setAuthor:_atomFeedAuthor];
			[newPost setFeedDbId:[feed dbId]];
			[newPost setFeedTitle:[feed title]];
			[newPost setFeedUrlString:[feed url]];
			
			for (CLXMLNode *childNode in [node children]) {
				
				NSString *childElementName = [childNode name];
				NSDictionary *childAttributeDict = [childNode attributes];
				NSString *childValue = [childNode combinedTextValue];
				
				if ([childElementName isEqual:@"link"]) {
					NSString *hrefValue = [childAttributeDict objectForKey:@"href"];
					NSString *relValue = [childAttributeDict objectForKey:@"rel"];
					
					// if it doesn't have a rel value, this is probably the primary link, so use it
					if (hrefValue != nil && relValue == nil) {
						[newPost setLink:hrefValue];
					} else if (hrefValue != nil && [newPost link] == nil && relValue != nil) {
						
						// the "alternate" link is usually a safe bet too
						if ([relValue isEqual:@"alternate"]) {
							[newPost setLink:hrefValue];
						}
					}
					
					// or maybe this is an enclosure
					if (hrefValue != nil && relValue != nil) {
						if ([relValue isEqual:@"enclosure"]) {
							[[newPost enclosures] addObject:hrefValue];
						}
					}
				}
				
				if ([childElementName isEqual:@"author"]) {
					for (CLXMLNode *childChildNode in [childNode children]) {
						NSString *childChildElementName = [childChildNode name];
						
						if ([childChildElementName isEqual:@"name"]) {
							[newPost setAuthor:[[childChildNode combinedTextValue] gtm_stringByUnescapingFromHTML]];
						}
					}
				}
				
				if ([childElementName isEqual:@"id"]) {
					[newPost setGuid:childValue];
				}
				
				if ([childElementName isEqual:@"title"]) {
					[newPost setTitle:[childValue gtm_stringByUnescapingFromHTML]];
				}
				
				if ([childElementName isEqual:@"updated"]) {
					NSDate *parsedDate = [CLDateHelper dateFromInternetDateTimeString:childValue formatHint:CLDateFormatHintRFC3339];
					if (parsedDate) {
						[newPost setPublished:parsedDate];
					}
				}
				
				if ([childElementName isEqual:@"summary"]) {
					
					// only use this for the content if we don't have anything better
					if ([newPost content] == nil) {
						[newPost setContent:childValue];
					}
				}
				
				if ([childElementName isEqual:@"content"]) {
					[newPost setContent:childValue];
				}
			}
			
			if (([newPost title] != nil && [[newPost title] length] > 0) || ([newPost content] != nil && [[newPost content] length] > 0)) {
				
				if ([newPost content] != nil) {
					[newPost setPlainTextContent:[CLHTMLFilter extractPlainTextFromString:[newPost content]]];
				}
				
				[allPosts addObject:newPost];
			}
			
			[newPost release];
			
			shouldProcessChildren = NO;
		}
	}
	
	if (shouldProcessChildren) {
		for (CLXMLNode *childNode in [node children]) {
			[self processNode:childNode];
		}
	}
}

- (void)dispatchNewPostsDelegateMessage {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	[delegate feedParserOperationFoundNewPostsForFeed:feed];
}

- (void)dispatchTitleDelegateMessage {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	[delegate feedParserOperationFoundTitleForFeed:feed];
}

- (void)dispatchWebsiteLinkDelegateMessage {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	[delegate feedParserOperationFoundWebsiteLinkForFeed:feed];
}

@end
