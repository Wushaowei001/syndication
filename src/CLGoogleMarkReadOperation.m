//
//  CLGoogleMarkReadOperation.m
//  Syndication
//
//  Created by Calvin Lough on 4/12/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLGoogleMarkReadOperation.h"
#import "CLStringHelper.h"
#import "CLUrlFetcher.h"

@implementation CLGoogleMarkReadOperation

@synthesize feedGoogleUrl;
@synthesize itemGuid;

- (void)dealloc {
	[feedGoogleUrl release];
	[itemGuid release];
	
	[super dealloc];
}

- (void)main {
	
	@try {
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if (feedGoogleUrl == nil || [feedGoogleUrl length] == 0 || itemGuid == nil || [itemGuid length] == 0) {
			[self completeOperation];
			[pool drain];
			return;
		}
		
		NSString *token = nil;
		NSInteger statusCode = 0;
		NSData *tokenData = [self fetchTokenUsingAuth:googleAuth statusCode:&statusCode];
		
		if ([CLUrlFetcher isSuccessStatusCode:statusCode] == NO || tokenData == nil) {
			if ([self resetAuth] == NO) {
				[pool drain];
				return;
			}
			
			tokenData = [self fetchTokenUsingAuth:googleAuth statusCode:&statusCode];
		}
		
		if ([CLUrlFetcher isSuccessStatusCode:statusCode] && tokenData != nil && [tokenData length] > 0) {
			token = [CLStringHelper stringFromData:tokenData withPossibleEncoding:NSUTF8StringEncoding];
		}
		
		if (token == nil || [token length] == 0) {
			[self completeOperation];
			[pool drain];
			return;
		}
		
		[self addTag:@"user/-/state/com.google/read" forUrlString:feedGoogleUrl item:itemGuid token:token auth:googleAuth statusCode:&statusCode];
		
		if ([CLUrlFetcher isSuccessStatusCode:statusCode] == NO) {
			if ([self resetAuth] == NO) {
				[pool drain];
				return;
			}
			
			[self addTag:@"user/-/state/com.google/read" forUrlString:feedGoogleUrl item:itemGuid token:token auth:googleAuth statusCode:&statusCode];
		}
		
		[self completeOperation];
		[pool drain];
		
	} @catch(...) {
		// Do not rethrow exceptions.
	}
}

@end
