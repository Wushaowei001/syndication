//
//  CLDatabaseHelper.m
//  Syndication
//
//  Created by Calvin Lough on 02/02/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLDatabaseHelper.h"
#import "NSFileManager+CLAdditions.h"

@implementation CLDatabaseHelper

static NSString *path;

+ (NSString *)pathForDatabaseFile {
	
	if (path == nil) {
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *folder = [fileManager clSyndicationSupportDirectory];
		NSString *fileName = @"SyndicationDatabase";
		
		path = [[folder stringByAppendingPathComponent:fileName] retain];
	}
	
	return path;
}

@end
