//
//  CLGoogleMarkReadOperation.h
//  Syndication
//
//  Created by Calvin Lough on 4/12/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLGoogleOperation.h"

@interface CLGoogleMarkReadOperation : CLGoogleOperation {
	NSString *feedGoogleUrl;
	NSString *itemGuid;
}

@property (copy) NSString *feedGoogleUrl;
@property (copy) NSString *itemGuid;

@end
