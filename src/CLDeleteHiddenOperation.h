//
//  CLDeleteHiddenOperation.h
//  Syndication
//
//  Created by Calvin Lough on 7/2/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLOperation.h"

@interface CLDeleteHiddenOperation : CLOperation {
	NSArray *nonGoogleFeeds;
	NSArray *googleFeeds;
}

@property (retain, nonatomic) NSArray *nonGoogleFeeds;
@property (retain, nonatomic) NSArray *googleFeeds;

@end
