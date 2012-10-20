//
//  CLUrlFetcher.m
//  Syndication
//
//  Created by Calvin Lough on 4/7/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLUrlFetcher.h"

@implementation CLUrlFetcher

+ (NSData *)fetchUrlString:(NSString *)urlString postData:(NSData *)postData usingAuth:(NSString *)auth returnNilOnFailure:(BOOL)nilOnFail urlResponse:(NSURLResponse **)urlResponse {
	
	NSURL *fetchUrl = [NSURL URLWithString:urlString];
	
	if (fetchUrl == nil) {
		CLLog(@"invalid url");
		return nil;
	}
	
	NSMutableURLRequest *fetchUrlRequest = [NSMutableURLRequest requestWithURL:fetchUrl
																   cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
															   timeoutInterval:URL_REQUEST_TIMEOUT];
	
	if (auth != nil) {
		[fetchUrlRequest setValue:[NSString stringWithFormat:@"GoogleLogin auth=%@", auth] forHTTPHeaderField:@"Authorization"];
	}
	
	[fetchUrlRequest setHTTPShouldHandleCookies:NO];
	
	if (postData != nil) {
		[fetchUrlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[fetchUrlRequest setValue:[NSString stringWithFormat:@"%ld", [postData length]] forHTTPHeaderField:@"Content-Length"];
		[fetchUrlRequest setHTTPMethod:@"POST"];
		[fetchUrlRequest setHTTPBody:postData];
	} else {
		[fetchUrlRequest setHTTPMethod:@"GET"];
	}
	
	NSData *fetchData = nil;
	NSURLResponse *fetchUrlResponse = nil;
	NSError *fetchError = nil;
	BOOL tryAgain = NO;
	
	do {
		fetchData = nil;
		fetchUrlResponse = nil;
		fetchError = nil;
		
		CLLog(@"before %@", urlString);
		fetchData = [NSURLConnection sendSynchronousRequest:fetchUrlRequest returningResponse:&fetchUrlResponse error:&fetchError];
		CLLog(@"after %@", urlString);
		tryAgain = NO;
		
		// keep trying if connection is offline
		if (fetchData == nil && fetchError != nil && [fetchError code] == -1009) {
			CLLog(@"connection offline... retrying %@ soon", urlString);
			
			[NSThread sleepForTimeInterval:OFFLINE_RETRY_PAUSE];
			
			CLLog(@"wake %@", urlString);
			
			fetchData = nil;
			fetchUrlResponse = nil;
			fetchError = nil;
			
			tryAgain = YES;
		}
		
	} while (tryAgain);
	
	CLLog(@"outside of loop");
	
	if (urlResponse != nil) {
		*urlResponse = fetchUrlResponse;
	}
	
	[[NSURLCache sharedURLCache] removeCachedResponseForRequest:fetchUrlRequest];
	
	if (fetchError != nil) {
		CLLog(@"code = %ld, error = %@, recovery = %@", [fetchError code], [fetchError localizedDescription], [fetchError localizedRecoverySuggestion]);
	}
	
	if ([fetchUrlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
		
		if ([CLUrlFetcher isSuccessStatusCode:[(NSHTTPURLResponse *)fetchUrlResponse statusCode]] == NO) {
			CLLog(@"%@ return code = %ld", urlString, [(NSHTTPURLResponse *)fetchUrlResponse statusCode]);
			
			NSDictionary *headers = [(NSHTTPURLResponse *)fetchUrlResponse allHeaderFields];
			NSArray *keys = [headers allKeys];
			
			CLLog(@"--------------- HEADERS -------------------");
			
			for (NSString *key in keys) {
				CLLog(@"%@: %@", key, [headers objectForKey:key]);
			}
			
			CLLog(@"-------------------------------------------");
			
			if (nilOnFail) {
				return nil;
			}
		}
	}
	
	CLLog(@"end of fetch");
	
	return fetchData;
}

+ (NSURLConnection *)fetchUrlString:(NSString *)urlString delegate:(id)delegate {
	
	NSURL *fetchUrl = [NSURL URLWithString:urlString];
	
	if (fetchUrl == nil) {
		CLLog(@"invalid url");
		return nil;
	}
	
	NSMutableURLRequest *fetchUrlRequest = [NSMutableURLRequest requestWithURL:fetchUrl cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:URL_REQUEST_TIMEOUT];
	[fetchUrlRequest setHTTPShouldHandleCookies:NO];
	[fetchUrlRequest setHTTPMethod:@"GET"];
	
	NSURLConnection *fetchUrlConnection = [[[NSURLConnection alloc] initWithRequest:fetchUrlRequest delegate:delegate startImmediately:YES] autorelease];
	
	return fetchUrlConnection;
}

+ (BOOL)isSuccessStatusCode:(NSInteger)code {
	if (code >= 200 && code < 300) {
		return YES;
	}
	
	return NO;
}

@end
