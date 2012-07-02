//
//  CLGoogleRemoveFromFolderOperation.h
//  Syndication
//
//  Created by Calvin Lough on 5/13/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLGoogleOperation.h"

@interface CLGoogleRemoveFromFolderOperation : CLGoogleOperation {
	NSString *feedGoogleUrl;
	NSString *folder;
}

@property (copy) NSString *feedGoogleUrl;
@property (copy) NSString *folder;

@end
