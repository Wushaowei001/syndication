//
//  CLGoogleFeedTitleOperation.h
//  Syndication
//
//  Created by Calvin Lough on 4/13/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLGoogleOperation.h"

@interface CLGoogleFeedTitleOperation : CLGoogleOperation {
	NSString *feedGoogleUrl;
	NSString *feedTitle;
}

@property (copy) NSString *feedGoogleUrl;
@property (copy) NSString *feedTitle;

@end
