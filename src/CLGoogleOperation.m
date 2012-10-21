//
//  CLGoogleOperation.m
//  Syndication
//
//  Created by Calvin Lough on 3/31/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLGoogleOperation.h"
#import "CLKeychainHelper.h"
#import "CLStringHelper.h"
#import "CLUrlFetcher.h"
#import "NSString+CLAdditions.h"
#import "SyndicationAppDelegate.h"

#define GOOGLE_READER_CLIENT @"in.calv.syndication"

@implementation CLGoogleOperation

@synthesize googleAuth;
@synthesize _isExecuting;
@synthesize _isFinished;

- (id)init {
	self = [super init];
	if (self != nil) {
		[self set_isExecuting:NO];
		[self set_isFinished:NO];
	}
	return self;
}

- (void)dealloc {
	[googleAuth release];
	
	[super dealloc];
}

- (id <CLGoogleOperationDelegate>)delegate {
	return (id <CLGoogleOperationDelegate>)[self _delegate];
}

- (void)setDelegate:(id <CLGoogleOperationDelegate>)delegate {
	[self set_delegate:delegate];
}

- (void)start {
	
	@try {
		
		if ([self isCancelled]) {
			[self willChangeValueForKey:@"isFinished"];
			[self set_isFinished:YES];
			[self didChangeValueForKey:@"isFinished"];
			return;
		}
		
		[self willChangeValueForKey:@"isExecuting"];
		[self set_isExecuting:YES];
		[self didChangeValueForKey:@"isExecuting"];
		
		[self performSelectorOnMainThread:@selector(dispatchDidStartDelegateMessage) withObject:nil waitUntilDone:YES];
		
		if ([self updateAuth]) {
			[NSThread sleepForTimeInterval:GOOGLE_REQUEST_PAUSE]; // give google's servers a break between requests
			[NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
		}
		
	} @catch(...) {
		// Do not rethrow exceptions.
	}
}

- (BOOL)isConcurrent {
	return YES;
}

- (BOOL)isExecuting {
	return _isExecuting;
}

- (BOOL)isFinished {
	return _isFinished;
}

- (void)completeOperation {
	[self performSelectorOnMainThread:@selector(dispatchDidFinishDelegateMessage) withObject:nil waitUntilDone:YES];
	
	[self willChangeValueForKey:@"isFinished"];
	[self willChangeValueForKey:@"isExecuting"];
	
	[self set_isExecuting:NO];
	[self set_isFinished:YES];
	
	[self didChangeValueForKey:@"isExecuting"];
	[self didChangeValueForKey:@"isFinished"];
}

- (void)restartOperation {
	if ([self updateAuth]) {
		[NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
	}
}

- (BOOL)updateAuth {
	if (googleAuth == nil || [googleAuth length] == 0) {
		
		NSString *googleEmail = [SyndicationAppDelegate miscellaneousValueForKey:MISCELLANEOUS_GOOGLE_EMAIL_KEY];
		NSString *googlePassword = [CLKeychainHelper getPasswordForAccount:googleEmail];
		
		if (googleEmail == nil || [googleEmail length] == 0 || googlePassword == nil || [googlePassword length] == 0) {
			[self performSelectorOnMainThread:@selector(dispatchAuthErrorDelegateMessage:) withObject:nil waitUntilDone:YES];
			// note that there is intentionally no call to completeOperation here (so this operation can be restarted later)
			return NO;
		}
		
		NSInteger statusCode = 0;
		NSDictionary *responseDict = [self doLoginWithEmail:googleEmail andPassword:googlePassword statusCode:&statusCode];
		
		googleEmail = nil;
		googlePassword = nil;
		
		if ([CLUrlFetcher isSuccessStatusCode:statusCode] && responseDict != nil && [responseDict isKindOfClass:[NSDictionary class]] && [responseDict objectForKey:@"Auth"] != nil) {
			[self setGoogleAuth:[responseDict objectForKey:@"Auth"]];
			[self performSelectorOnMainThread:@selector(dispatchAuthDelegateMessage) withObject:nil waitUntilDone:YES];
		} else {
			[self performSelectorOnMainThread:@selector(dispatchAuthErrorDelegateMessage:) withObject:responseDict waitUntilDone:YES];
			// note that there is intentionally no call to completeOperation here (so this operation can be restarted later)
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)resetAuth {
	[self setGoogleAuth:nil];
	[self performSelectorOnMainThread:@selector(dispatchAuthDelegateMessage) withObject:nil waitUntilDone:YES];
	
	return [self updateAuth];
}


# pragma mark google api stuff

- (NSData *)fetchUrlString:(NSString *)urlString postData:(NSData *)postData usingAuth:(NSString *)auth returnNilOnFailure:(BOOL)nilOnFail statusCode:(NSInteger *)statusCode {
	
	NSURLResponse *urlResponse = nil;
	NSData *fetchData = [CLUrlFetcher fetchUrlString:urlString postData:postData usingAuth:auth returnNilOnFailure:nilOnFail urlResponse:&urlResponse];
	
	if ([urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
		if (statusCode != nil) {
			*statusCode = [(NSHTTPURLResponse *)urlResponse statusCode];
		}
	} else {
		*statusCode = 200;
	}
	
	return fetchData;
}

- (NSDictionary *)doLoginWithEmail:(NSString *)email andPassword:(NSString *)password statusCode:(NSInteger *)statusCode {
	
	NSDictionary *authResponseDict = nil;
	NSString *authurlString = @"https://www.google.com/accounts/ClientLogin";
	NSString *escapedEmail = [email clUrlEncodedParameterString];
	NSString *escapedPassword = [password clUrlEncodedParameterString];
	NSString *postString = [NSString stringWithFormat:@"accountType=HOSTED_OR_GOOGLE&Email=%@&Passwd=%@&service=reader&source=%@", escapedEmail, escapedPassword, GOOGLE_READER_CLIENT];
	NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
	
	NSData *authResponse = [self fetchUrlString:authurlString postData:postData usingAuth:nil returnNilOnFailure:NO statusCode:statusCode];
	
	if (authResponse != nil && [CLUrlFetcher isSuccessStatusCode:*statusCode]) {
		NSString *authResponseString = [CLStringHelper stringFromData:authResponse withPossibleEncoding:NSUTF8StringEncoding];
		authResponseDict = [NSMutableDictionary dictionary];
		NSArray *responseLines = [authResponseString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		
		for (NSString *line in responseLines) {
			NSArray *lineParts = [line componentsSeparatedByString:@"="];
			if ([lineParts count] == 2) {
				[authResponseDict setValue:[lineParts objectAtIndex:1] forKey:[lineParts objectAtIndex:0]];
			}
		}
	}
	
	return authResponseDict;
}

- (NSData *)fetchFeedListUsingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = [NSString stringWithFormat:@"https://www.google.com/reader/api/0/subscription/list?output=json&ck=%lld&client=%@", (long long)[[NSDate date] timeIntervalSince1970], GOOGLE_READER_CLIENT];
	return [self fetchUrlString:requesturlString postData:nil usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}

- (NSData *)fetchUnreadCountsUsingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = [NSString stringWithFormat:@"https://www.google.com/reader/api/0/unread-count?output=json&allcomments=true&ck=%lld&client=%@", (long long)[[NSDate date] timeIntervalSince1970], GOOGLE_READER_CLIENT];
	return [self fetchUrlString:requesturlString postData:nil usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}

- (NSData *)fetch:(NSInteger)count itemsForUrlString:(NSString *)urlString since:(NSInteger)since usingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = [NSString stringWithFormat:@"https://www.google.com/reader/api/0/stream/contents/%@?output=json&ot=%ld&r=n&n=%ld&ck=%lld&client=%@", [urlString clUrlEncodedParameterString], since, count, (long long)[[NSDate date] timeIntervalSince1970], GOOGLE_READER_CLIENT];
	return [self fetchUrlString:requesturlString postData:nil usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}

- (NSData *)fetch:(NSInteger)count itemsForUrlString:(NSString *)urlString since:(NSInteger)since continuation:(NSString *)continuation usingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = [NSString stringWithFormat:@"https://www.google.com/reader/api/0/stream/contents/%@?output=json&ot=%ld&r=n&n=%ld&ck=%lld&c=%@&client=%@", [urlString clUrlEncodedParameterString], since, count, (long long)[[NSDate date] timeIntervalSince1970], continuation, GOOGLE_READER_CLIENT];
	return [self fetchUrlString:requesturlString postData:nil usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}

- (NSData *)fetch:(NSInteger)count unreadItemsForUrlString:(NSString *)urlString since:(NSInteger)since usingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = [NSString stringWithFormat:@"https://www.google.com/reader/api/0/stream/contents/%@?output=json&xt=user/-/state/com.google/read&ot=%ld&r=n&n=%ld&ck=%lld&client=%@", [urlString clUrlEncodedParameterString], since, count, (long long)[[NSDate date] timeIntervalSince1970], GOOGLE_READER_CLIENT];
	return [self fetchUrlString:requesturlString postData:nil usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}

- (NSData *)fetch:(NSInteger)count unreadItemsForUrlString:(NSString *)urlString since:(NSInteger)since continuation:(NSString *)continuation usingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = [NSString stringWithFormat:@"https://www.google.com/reader/api/0/stream/contents/%@?output=json&xt=user/-/state/com.google/read&ot=%ld&r=n&n=%ld&ck=%lld&c=%@&client=%@", [urlString clUrlEncodedParameterString], since, count, (long long)[[NSDate date] timeIntervalSince1970], continuation, GOOGLE_READER_CLIENT];
	return [self fetchUrlString:requesturlString postData:nil usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}

- (NSData *)fetch:(NSInteger)count starredItemsUsingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = [NSString stringWithFormat:@"https://www.google.com/reader/api/0/stream/contents/user/-/state/com.google/starred?output=json&n=%ld&ck=%lld&client=%@", count, (long long)[[NSDate date] timeIntervalSince1970], GOOGLE_READER_CLIENT];
	return [self fetchUrlString:requesturlString postData:nil usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}

- (NSData *)fetch:(NSInteger)count starredItemsUsingAuth:(NSString *)auth continuation:(NSString *)continuation statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = [NSString stringWithFormat:@"https://www.google.com/reader/api/0/stream/contents/user/-/state/com.google/starred?output=json&n=%ld&ck=%lld&c=%@&client=%@", count, (long long)[[NSDate date] timeIntervalSince1970], continuation, GOOGLE_READER_CLIENT];
	return [self fetchUrlString:requesturlString postData:nil usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}

- (NSData *)fetchTokenUsingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = @"https://www.google.com/reader/api/0/token";
	return [self fetchUrlString:requesturlString postData:nil usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}

- (NSData *)addToFolder:(NSString *)folder forUrlString:(NSString *)urlString token:(NSString *)token auth:(NSString *)auth statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = [NSString stringWithFormat:@"https://www.google.com/reader/api/0/subscription/edit?client=%@", GOOGLE_READER_CLIENT];
	NSString *escapedFolder = [folder clUrlEncodedParameterString];
	NSString *escapedUrlString = [urlString clUrlEncodedParameterString];
	NSString *escapedToken = [token clUrlEncodedParameterString];
	NSString *postString = [NSString stringWithFormat:@"s=%@&ac=edit&a=user/-/label/%@&T=%@", escapedUrlString, escapedFolder, escapedToken];
	NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
	return [self fetchUrlString:requesturlString postData:postData usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}

- (NSData *)removeFromFolder:(NSString *)folder forUrlString:(NSString *)urlString token:(NSString *)token auth:(NSString *)auth statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = [NSString stringWithFormat:@"https://www.google.com/reader/api/0/subscription/edit?client=%@", GOOGLE_READER_CLIENT];
	NSString *escapedFolder = [folder clUrlEncodedParameterString];
	NSString *escapedUrlString = [urlString clUrlEncodedParameterString];
	NSString *escapedToken = [token clUrlEncodedParameterString];
	NSString *postString = [NSString stringWithFormat:@"s=%@&ac=edit&r=user/-/label/%@&T=%@", escapedUrlString, escapedFolder, escapedToken];
	NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
	return [self fetchUrlString:requesturlString postData:postData usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}

- (NSData *)addTag:(NSString *)tag forUrlString:(NSString *)urlString item:(NSString *)item token:(NSString *)token auth:(NSString *)auth statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = [NSString stringWithFormat:@"https://www.google.com/reader/api/0/edit-tag?client=%@", GOOGLE_READER_CLIENT];
	NSString *escapedTag = [tag clUrlEncodedParameterString];
	NSString *escapedUrlString = [urlString clUrlEncodedParameterString];
	NSString *escapedItem = [item clUrlEncodedParameterString];
	NSString *escapedToken = [token clUrlEncodedParameterString];
	NSString *postString = [NSString stringWithFormat:@"a=%@&s=%@&i=%@&T=%@", escapedTag, escapedUrlString, escapedItem, escapedToken];
	NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
	return [self fetchUrlString:requesturlString postData:postData usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}

- (NSData *)removeTag:(NSString *)tag forUrlString:(NSString *)urlString item:(NSString *)item token:(NSString *)token auth:(NSString *)auth statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = [NSString stringWithFormat:@"https://www.google.com/reader/api/0/edit-tag?client=%@", GOOGLE_READER_CLIENT];
	NSString *escapedTag = [tag clUrlEncodedParameterString];
	NSString *escapedUrlString = [urlString clUrlEncodedParameterString];
	NSString *escapedItem = [item clUrlEncodedParameterString];
	NSString *escapedToken = [token clUrlEncodedParameterString];
	NSString *postString = [NSString stringWithFormat:@"r=%@&s=%@&i=%@&T=%@", escapedTag, escapedUrlString, escapedItem, escapedToken];
	NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
	return [self fetchUrlString:requesturlString postData:postData usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}

- (NSData *)addSubscriptionForUrlString:(NSString *)urlString token:(NSString *)token auth:(NSString *)auth statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = [NSString stringWithFormat:@"https://www.google.com/reader/api/0/subscription/edit?client=%@", GOOGLE_READER_CLIENT];
	NSString *escapedUrlString = [urlString clUrlEncodedParameterString];
	NSString *escapedToken = [token clUrlEncodedParameterString];
	NSString *postString = [NSString stringWithFormat:@"s=%@&ac=subscribe&T=%@", escapedUrlString, escapedToken];
	NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
	return [self fetchUrlString:requesturlString postData:postData usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}

- (NSData *)deleteSubscriptionForUrlString:(NSString *)urlString token:(NSString *)token auth:(NSString *)auth statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = [NSString stringWithFormat:@"https://www.google.com/reader/api/0/subscription/edit?client=%@", GOOGLE_READER_CLIENT];
	NSString *escapedUrlString = [urlString clUrlEncodedParameterString];
	NSString *escapedToken = [token clUrlEncodedParameterString];
	NSString *postString = [NSString stringWithFormat:@"s=%@&ac=unsubscribe&T=%@", escapedUrlString, escapedToken];
	NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
	return [self fetchUrlString:requesturlString postData:postData usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}

- (NSData *)updateTitle:(NSString *)title forUrlString:(NSString *)urlString token:(NSString *)token auth:(NSString *)auth statusCode:(NSInteger *)statusCode {
	NSString *requesturlString = [NSString stringWithFormat:@"https://www.google.com/reader/api/0/subscription/edit?client=%@", GOOGLE_READER_CLIENT];
	NSString *escapedTitle = [title clUrlEncodedParameterString];
	NSString *escapedUrlString = [urlString clUrlEncodedParameterString];
	NSString *escapedToken = [token clUrlEncodedParameterString];
	NSString *postString = [NSString stringWithFormat:@"s=%@&ac=edit&t=%@&T=%@", escapedUrlString, escapedTitle, escapedToken];
	NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
	return [self fetchUrlString:requesturlString postData:postData usingAuth:auth returnNilOnFailure:YES statusCode:statusCode];
}


- (void)dispatchAuthDelegateMessage {
	if ([NSThread isMainThread] == NO) {
		[NSException raise:@"Thread error" format:@"This function should only be called from the main thread!"];
	}
	
	[[self delegate] googleOperation:self foundAuthToken:googleAuth];
}

- (void)dispatchAuthErrorDelegateMessage:(NSDictionary *)authError {
	if ([NSThread isMainThread] == NO) {
		[NSException raise:@"Thread error" format:@"This function should only be called from the main thread!"];
	}
	
	[[self delegate] googleOperation:self handleAuthError:authError];
}

@end
