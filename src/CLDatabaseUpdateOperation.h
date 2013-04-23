//
//  CLDatabaseUpdateOperation.h
//  Syndication
//
//  Created by Calvin Lough on 11/3/12.
//  Copyright (c) 2012 Calvin Lough. All rights reserved.
//

#import "CLOperation.h"

@interface CLDatabaseUpdateOperation : CLOperation {
	NSArray *queries;
}

@property (copy, nonatomic) NSArray *queries;

@end
