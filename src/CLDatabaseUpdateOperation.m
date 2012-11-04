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

@synthesize queryString;
@synthesize parameters;

- (void)dealloc {
	[queryString release];
	[parameters release];
	
	[super dealloc];
}

- (void)main {
	
	@try {
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		FMDatabase *db = [FMDatabase databaseWithPath:[CLDatabaseHelper pathForDatabaseFile]];
		
		if (![db open]) {
			[NSException raise:@"Database error" format:@"Failed to connect to the database!"];
		}
		
		[db executeUpdate:queryString withArgumentsInArray:parameters];
		
		[db close];
		
		[self performSelectorOnMainThread:@selector(dispatchDidFinishDelegateMessage) withObject:nil waitUntilDone:YES];
		
		[pool drain];
		
	} @catch(...) {
		// Do not rethrow exceptions.
	}
}

@end
