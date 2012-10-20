//
//  CLFeedRequest.m
//  Syndication
//
//  Created by Calvin Lough on 6/23/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLFeedRequest.h"
#import "CLSourceListFeed.h"
#import "CLTimer.h"
#import "CLUrlFetcher.h"

@implementation CLFeedRequest

@synthesize delegate;
@synthesize feed;
@synthesize urlConnection;
@synthesize urlResponse;
@synthesize receivedData;
@synthesize safetyTimer;

- (id)init {
	self = [super init];
	if (self != nil) {
		[self setReceivedData:[NSMutableData data]];
	}
	return self;
}

- (void)dealloc {
	CLLog(@"feed request dealloc");
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	if ([safetyTimer isValid]) {
		[safetyTimer invalidate];
	}
	
	[feed release];
	[urlConnection release];
	[urlResponse release];
	[receivedData release];
	[safetyTimer release];
	
	[super dealloc];
}

- (void)startConnection {
	CLLog(@"starting connection for %@", [feed extractTitleForDisplay]);
	
	if ([safetyTimer isValid]) {
		[safetyTimer invalidate];
		[self setSafetyTimer:nil];
	}
	
	[receivedData setLength:0];
	[self setUrlConnection:nil];
	[self setUrlResponse:nil];
	
	NSString *feedUrlString = [feed url];
	
	if (feedUrlString == nil) {
		[delegate feedRequest:self didFinishWithData:nil encoding:0];
		return;
	}
	
	if ([[feedUrlString substringToIndex:7] isEqual:@"feed://"]) {
		feedUrlString = [NSString stringWithFormat:@"http://%@", [feedUrlString substringFromIndex:7]];
	}
	
	NSURLConnection *conn = [CLUrlFetcher fetchUrlString:feedUrlString delegate:self];
	
	if (conn == nil) {
		[delegate feedRequest:self didFinishWithData:nil encoding:0];
		return;
	}
	
	[self setUrlConnection:conn];
	
	CLTimer *timer = [CLTimer scheduledTimerWithTimeInterval:(URL_REQUEST_TIMEOUT + 20) target:self selector:@selector(stopConnection) userInfo:nil repeats:NO];
	[self setSafetyTimer:timer];
}

- (void)stopConnection {
	CLLog(@"stopping connection for %@", [feed extractTitleForDisplay]);
	
	[urlConnection cancel];
	
	if ([safetyTimer isValid]) {
		[safetyTimer invalidate];
		[self setSafetyTimer:nil];
	}
	
	[delegate feedRequest:self didFinishWithData:nil encoding:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	CLLog(@"didReceiveResponse %@", [feed extractTitleForDisplay]);
	
	/*CLLog(@"----------------------------");
	CLLog(@"url: %@", [[response URL] absoluteString]);
	
	if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
		CLLog(@"status code: %ld", [(NSHTTPURLResponse *)response statusCode]);
		
		NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
		NSArray *keys = [headers allKeys];
		
		for (NSString *key in keys) {
			CLLog(@"%@: %@", key, [headers objectForKey:key]);
		}
	}
	
	CLLog(@"----------------------------");*/
	
	[self setUrlResponse:response];
	
	[receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[receivedData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
	return nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	CLLog(@"didFailWithError %@ %ld", [feed extractTitleForDisplay], [error code]);
	
	if ([error code] == -1009) {
		CLLog(@"feed parse offline... retrying %@ soon", [feed extractTitleForDisplay]);
		
		[self performSelector:@selector(startConnection) withObject:nil afterDelay:OFFLINE_RETRY_PAUSE];
		
		CLLog(@"timer set for retry...");
		
		return;
	}
	
	CLLog(@"after");
	
	if ([safetyTimer isValid]) {
		[safetyTimer invalidate];
		[self setSafetyTimer:nil];
	}
	
	[delegate feedRequest:self didFinishWithData:nil encoding:0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	CLLog(@"connectionDidFinishLoading %@", [feed extractTitleForDisplay]);
	
	if ([safetyTimer isValid]) {
		[safetyTimer invalidate];
		[self setSafetyTimer:nil];
	}
	
	NSString *textEncodingName = [urlResponse textEncodingName];
	NSStringEncoding stringEncoding = NSUTF8StringEncoding;
	
	if (textEncodingName != nil) {
		CFStringEncoding cfStringEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)textEncodingName);
		stringEncoding = CFStringConvertEncodingToNSStringEncoding(cfStringEncoding);
	}
	
	[delegate feedRequest:self didFinishWithData:receivedData encoding:stringEncoding];
}

@end
