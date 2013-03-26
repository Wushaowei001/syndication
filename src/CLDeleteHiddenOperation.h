//
//  CLDeleteHiddenOperation.h
//  Syndication
//
//  Created by Calvin Lough on 7/2/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLOperation.h"

@interface CLDeleteHiddenOperation : CLOperation {
	NSArray *feeds;
}

@property (retain, nonatomic) NSArray *feeds;

@end
