//
//  CLGoogleDeleteFeedOperation.h
//  Syndication
//
//  Created by Calvin Lough on 4/13/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLGoogleOperation.h"

@interface CLGoogleDeleteFeedOperation : CLGoogleOperation {
	NSString *feedGoogleUrl;
}

@property (copy) NSString *feedGoogleUrl;

@end
