//
//  CLDatabaseUpdateOperation.h
//  Syndication
//
//  Created by Calvin Lough on 11/3/12.
//  Copyright (c) 2012 Calvin Lough. All rights reserved.
//

#import "CLOperation.h"

@interface CLDatabaseUpdateOperation : CLOperation {
	NSString *queryString;
	NSArray *parameters;
}

@property (copy, nonatomic) NSString *queryString;
@property (copy, nonatomic) NSArray *parameters;

@end
