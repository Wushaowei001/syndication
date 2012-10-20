//
//  CLIconRefreshOperation.m
//  Syndication
//
//  Created by Calvin Lough on 3/15/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLDatabaseHelper.h"
#import "CLIconRefreshOperation.h"
#import "CLSourceListFeed.h"
#import "CLUrlFetcher.h"
#import "FMDatabase.h"

@implementation CLIconRefreshOperation

@synthesize delegate;
@synthesize feed;
@synthesize favicon;

- (void)dealloc {
	[feed release];
	[favicon release];
	
	[super dealloc];
}

- (void)main {
	
	@try {
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		CLLog(@"refreshing favicon for %@...", [feed websiteLink]);
		
		[self performSelectorOnMainThread:@selector(dispatchDidStartDelegateMessage) withObject:nil waitUntilDone:YES];
		
		if (feed == nil || [feed websiteLink] == nil || [[feed websiteLink] length] == 0) {
			[self performSelectorOnMainThread:@selector(dispatchDidFinishDelegateMessage) withObject:nil waitUntilDone:YES];
			[pool drain];
			return;
		}
		
		if ([feed websiteLink] != nil && [[feed websiteLink] length] > 0) {
			[self setFavicon:[self faviconForUrlString:[feed websiteLink]]];
		}
		
		if (favicon == nil) {
			CLLog(@"favicon null");
		} else {
			CLLog(@"favicon not null");
		}
		
		[self performSelectorOnMainThread:@selector(dispatchIconRefreshDelegateMessage) withObject:nil waitUntilDone:YES];
		
		[self performSelectorOnMainThread:@selector(dispatchDidFinishDelegateMessage) withObject:nil waitUntilDone:YES];
		
		[pool drain];
		
	} @catch(...) {
		// Do not rethrow exceptions.
	}
}

- (NSImage *)faviconForUrlString:(NSString *)urlString {
	NSString *faviconPath = nil;
	NSData *faviconData = nil;
	NSImage *faviconImage = nil;
	NSURLResponse *faviconUrlResponse;
	NSURL *faviconurl = [NSURL URLWithString:urlString];
	//NSDictionary *faviconHeaders = nil;
	//NSString *faviconContentType = nil;
	
	if (faviconurl != nil && [[faviconurl host] length] > 0) {
		
		faviconPath = [NSString stringWithFormat:@"http://%@/favicon.ico", [faviconurl host]];
		faviconData = [CLUrlFetcher fetchUrlString:faviconPath postData:nil usingAuth:nil returnNilOnFailure:YES urlResponse:&faviconUrlResponse];
		
		if (faviconData != nil) {
			/* faviconHeaders = [faviconUrlResponse allHeaderFields];
			faviconContentType = [faviconHeaders objectForKey:@"Content-Type"];
			
			if (faviconContentType != nil) {
				CLLog(@"content type: %@", faviconContentType);
			} */
			
			faviconImage = [[[NSImage alloc] initWithDataIgnoringOrientation:faviconData] autorelease];
			
			if (faviconImage == nil) {
				CLLog(@"couldn't create favicon");
			}
		}
		
		if (faviconImage == nil) {
			NSString *fullHost = [faviconurl host];
			
			// check for a subdomain
			NSArray *hostParts = [fullHost componentsSeparatedByString:@"."];
			
			// we want to match something like mail.google.com and not things like johnsmith.co.uk
			if ([hostParts count] > 2 && [[hostParts objectAtIndex:1] length] > 2) {
				NSString *newHost = [NSString stringWithFormat:@"%@.%@", [hostParts objectAtIndex:1], [hostParts objectAtIndex:2]];
				faviconPath = [NSString stringWithFormat:@"http://%@/favicon.ico", newHost];
				faviconData = [CLUrlFetcher fetchUrlString:faviconPath postData:nil usingAuth:nil returnNilOnFailure:YES urlResponse:&faviconUrlResponse];
				
				if (faviconData != nil) {
					/* faviconHeaders = [faviconUrlResponse allHeaderFields];
					faviconContentType = [faviconHeaders objectForKey:@"Content-Type"];
					
					if (faviconContentType != nil) {
					CLLog(@"content type: %@", faviconContentType);
					} */
					
					faviconImage = [[[NSImage alloc] initWithDataIgnoringOrientation:faviconData] autorelease];
					
					if (faviconImage == nil) {
						CLLog(@"couldn't create favicon");
					}
				}
			}
		}
	}
	
	return faviconImage;
}

- (void)dispatchIconRefreshDelegateMessage {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	[delegate iconRefreshOperation:self refreshedFeed:feed foundIcon:favicon];
}

@end