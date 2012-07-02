//
//  CLFeedRequest.h
//  Syndication
//
//  Created by Calvin Lough on 6/23/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLFeedRequestDelegate.h"

@class CLTimer;
@class CLXMLNode;

@interface CLFeedRequest : NSObject {
	id <CLFeedRequestDelegate> delegate;
	CLSourceListFeed *feed;
	NSURLConnection *urlConnection;
	NSURLResponse *urlResponse;
	NSMutableData *receivedData;
	CLTimer *safetyTimer;
}

@property (assign) id <CLFeedRequestDelegate> delegate;
@property (retain) CLSourceListFeed *feed;
@property (retain) NSURLConnection *urlConnection;
@property (retain) NSURLResponse *urlResponse;
@property (retain) NSMutableData *receivedData;
@property (retain) CLTimer *safetyTimer;

- (void)startConnection;
- (void)stopConnection;

@end
