//
//  CLFeedRequestDelegate.h
//  Syndication
//
//  Created by Calvin Lough on 6/23/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@class CLFeedRequest;
@class CLSourceListFeed;

@protocol CLFeedRequestDelegate

- (void)feedRequest:(CLFeedRequest *)feedRequest didFinishWithData:(NSData *)data encoding:(NSStringEncoding)encoding;

@end
