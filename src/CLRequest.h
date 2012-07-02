//
//  CLRequest.h
//  Syndication
//
//  Created by Calvin Lough on 7/2/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

typedef enum {CLRequestNonGoogleSync, CLRequestGoogleSync, CLRequestGoogleStarredSync, CLRequestSpecificFeedsSync, CLRequestGoogleSingleFeedSync, CLRequestDeleteHidden} CLRequestType;

@class CLSourceListFeed;

@interface CLRequest : NSObject {
	CLRequestType requestType;
	NSArray *specificFeeds;
	CLSourceListFeed *singleFeed;
}

@property (assign, nonatomic) CLRequestType requestType;
@property (retain, nonatomic) NSArray *specificFeeds;
@property (retain, nonatomic) CLSourceListFeed *singleFeed;

@end
