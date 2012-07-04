//
//  NSFileManager+CLAdditions.m
//  Syndication
//
//  Created by Calvin Lough on 01/08/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "NSFileManager+CLAdditions.h"

@implementation NSFileManager (CLAdditions)

- (NSString *)clApplicationSupportDirectory {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	
	if ([paths count] == 0)	{
		return nil;
	}
	
	// only need the first path returned
	NSString *resolvedPath = [paths objectAtIndex:0];
	
	return resolvedPath;
}

- (NSString *)clSyndicationSupportDirectory {
	NSString *supportDirectory = [self clApplicationSupportDirectory];
	NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
	NSString *syndicationSupportDirectory = [supportDirectory stringByAppendingPathComponent:executableName];
	
	BOOL isDirectory = NO;
	BOOL exists = [self fileExistsAtPath:syndicationSupportDirectory isDirectory:&isDirectory];
	
    if (exists && !isDirectory) {
		CLLog(@"Application support directory exists but is not a directory");
        return nil;
    }
    
	if (!exists) {
		BOOL success = [self createDirectoryAtPath:syndicationSupportDirectory withIntermediateDirectories:YES attributes:nil error:nil];
		if (!success) {
			CLLog(@"Unable to create application support directory");
			return nil;
		}
	}
	
	return syndicationSupportDirectory;
}

- (void)clCopyLiteDirectoryIfItExistsAndRegularDirectoryDoesnt {
    NSString *supportDirectory = [self clApplicationSupportDirectory];
	NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
	
	// if this accidently gets called from the Lite version itself, don't do anything
	if ([executableName hasSuffix:@"Lite"]) {
		return;
	}
	
	NSString *liteExecutableName = [executableName stringByAppendingString:@" Lite"];
	NSString *syndicationSupportDirectory = [supportDirectory stringByAppendingPathComponent:executableName];
	NSString *syndicationLiteSupportDirectory = [supportDirectory stringByAppendingPathComponent:liteExecutableName];
	
	BOOL liteIsDirectory = NO;
	BOOL liteExists = [self fileExistsAtPath:syndicationLiteSupportDirectory isDirectory:&liteIsDirectory];
	BOOL regularExists = [self fileExistsAtPath:syndicationSupportDirectory];
	
	if (liteExists && liteIsDirectory && !regularExists) {
		BOOL success = [self copyItemAtPath:syndicationLiteSupportDirectory toPath:syndicationSupportDirectory error:nil];
		if (!success) {
			CLLog(@"Unable to copy lite directory");
		}
	}
}

@end
