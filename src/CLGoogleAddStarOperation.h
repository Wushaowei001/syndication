//
//  CLGoogleAddStarOperation.h
//  Syndication
//
//  Created by Calvin Lough on 6/16/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLGoogleOperation.h"

@interface CLGoogleAddStarOperation : CLGoogleOperation {
	NSString *feedGoogleUrl;
	NSString *itemGuid;
}

@property (copy) NSString *feedGoogleUrl;
@property (copy) NSString *itemGuid;

@end
