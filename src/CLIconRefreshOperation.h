//
//  CLIconRefreshOperation.h
//  Syndication
//
//  Created by Calvin Lough on 3/15/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLIconRefreshOperationDelegate.h"
#import "CLOperation.h"

@class CLSourceListFeed;

@interface CLIconRefreshOperation : CLOperation {
	id <CLIconRefreshOperationDelegate> delegate;
	CLSourceListFeed *feed;
	NSImage *favicon;
}

@property (assign) id <CLIconRefreshOperationDelegate> delegate;
@property (retain) CLSourceListFeed *feed;
@property (retain) NSImage *favicon;

- (NSImage *)faviconForUrlString:(NSString *)urlString;
- (void)dispatchIconRefreshDelegateMessage;

@end
