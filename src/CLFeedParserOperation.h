//
//  CLFeedParserOperation.h
//  Syndication
//
//  Created by Calvin Lough on 6/23/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLOperation.h"
#import "CLFeedParserOperationDelegate.h"

@class CLSourceListFeed;
@class CLXMLNode;

@interface CLFeedParserOperation : CLOperation {
	id <CLFeedParserOperationDelegate> delegate;
	CLSourceListFeed *feed;
	NSData *data;
	NSStringEncoding encoding;
	NSMutableArray *allPosts;
	NSString *_atomFeedAuthor;
	NSInteger _feedType;
}

@property (assign) id <CLFeedParserOperationDelegate> delegate;
@property (retain) CLSourceListFeed *feed;
@property (retain) NSData *data;
@property (assign) NSStringEncoding encoding;
@property (retain) NSMutableArray *allPosts;
@property (copy) NSString *_atomFeedAuthor;
@property (assign) NSInteger _feedType;

- (void)processNode:(CLXMLNode *)node;

- (void)dispatchNewPostsDelegateMessage;
- (void)dispatchTitleDelegateMessage;
- (void)dispatchWebsiteLinkDelegateMessage;

@end
