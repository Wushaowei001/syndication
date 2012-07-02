//
//  CLErrorHelper.m
//  Syndication
//
//  Created by Calvin Lough on 02/03/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLErrorHelper.h"

@implementation CLErrorHelper

+ (void)createAndDisplayError:(NSString *)message {
	NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
	[errorDetail setValue:message forKey:NSLocalizedDescriptionKey];
	NSError *error = [NSError errorWithDomain:@"CLDomain" code:0 userInfo:errorDetail];
	[NSApp presentError:error];
}

@end
