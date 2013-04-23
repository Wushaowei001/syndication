//
//  CLDatabaseUpdateOperation.m
//  Syndication
//
//  Created by Calvin Lough on 11/3/12.
//  Copyright (c) 2012 Calvin Lough. All rights reserved.
//

#import "CLDatabaseHelper.h"
#import "CLDatabaseUpdateOperation.h"
#import "FMDatabase.h"

@implementation CLDatabaseUpdateOperation

@synthesize queries;

- (void)dealloc {
	[queries release];
	
	[super dealloc];
}

- (void)main {
	
	@try {
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		FMDatabase *db = [FMDatabase databaseWithPath:[CLDatabaseHelper pathForDatabaseFile]];
		
		if (![db open]) {
			[NSException raise:@"Database error" format:@"Failed to connect to the database!"];
		}
		
		[db beginTransaction];
		
		for (NSArray *query in queries) {
			NSString *queryString = [query objectAtIndex:0];
			NSArray *parameters = nil;
			
			if ([query count] > 1) {
				parameters = [query subarrayWithRange:NSMakeRange(1, [query count] - 1)];
			}
			
			[db executeUpdate:queryString withArgumentsInArray:parameters];
		}
		
		[db commit];
		
		[db close];
		
		[self performSelectorOnMainThread:@selector(dispatchDidFinishDelegateMessage) withObject:nil waitUntilDone:YES];
		
		[pool drain];
		
	} @catch(...) {
		// Do not rethrow exceptions.
	}
}

@end
