//
//  CLGoogleAddToFolderOperation.m
//  Syndication
//
//  Created by Calvin Lough on 5/13/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLGoogleAddToFolderOperation.h"
#import "CLStringHelper.h"
#import "CLUrlFetcher.h"

@implementation CLGoogleAddToFolderOperation

@synthesize feedGoogleUrl;
@synthesize folder;

- (void)dealloc {
	[feedGoogleUrl release];
	[folder release];
	
	[super dealloc];
}

- (void)main {
	
	@try {
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		CLLog(@"adding %@... to folder %@", feedGoogleUrl, folder);
		
		if (feedGoogleUrl == nil || [feedGoogleUrl length] == 0 || folder == nil || [folder length] == 0) {
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
		
		[self addToFolder:folder forUrlString:feedGoogleUrl token:token auth:googleAuth statusCode:&statusCode];
		
		if ([CLUrlFetcher isSuccessStatusCode:statusCode] == NO) {
			if ([self resetAuth] == NO) {
				[pool drain];
				return;
			}
			
			[self addToFolder:folder forUrlString:feedGoogleUrl token:token auth:googleAuth statusCode:&statusCode];
		}
		
		CLLog(@"finished...");
		
		[self completeOperation];
		[pool drain];
		
	} @catch(...) {
		// Do not rethrow exceptions.
	}
}

@end
