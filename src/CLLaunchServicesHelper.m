//
//  CLLaunchServicesHelper.m
//  Syndication
//
//  Created by Calvin Lough on 3/21/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLLaunchServicesHelper.h"

@implementation CLLaunchServicesHelper

+ (void)setDefaultHandlerForUrlScheme:(NSString *)scheme bundleId:(NSString *)bundleId {
	LSSetDefaultHandlerForURLScheme((CFStringRef)scheme, (CFStringRef)bundleId);
}

+ (NSString *)defaultHandlerForUrlScheme:(NSString *)scheme {
	return [(NSString *)LSCopyDefaultHandlerForURLScheme((CFStringRef)scheme) autorelease];
}

+ (NSArray *)allHandlersForUrlScheme:(NSString *)scheme {
	return [(NSArray *)LSCopyAllHandlersForURLScheme((CFStringRef)scheme) autorelease];
}

+ (NSString *)nameForBundleId:(NSString *)bundleId {
	FSRef theFSRef;
	LSFindApplicationForInfo(kLSUnknownCreator, (CFStringRef)bundleId, NULL, &theFSRef, NULL);
	
	NSString *name = [NSString string];
	LSCopyDisplayNameForRef(&theFSRef, (CFStringRef *)&name);
	
	return name;
}

+ (NSImage *)iconForBundleId:(NSString *)bundleId {
	FSRef theFSRef;
	LSFindApplicationForInfo(kLSUnknownCreator, (CFStringRef)bundleId, NULL, &theFSRef, NULL);
	
	IconRef iconRef;
	GetIconRefFromFileInfo(&theFSRef, 0, NULL, 0, NULL, kIconServicesNormalUsageFlag, &iconRef, NULL);
	NSImage *image = [[[NSImage alloc] initWithIconRef:iconRef] autorelease];
	ReleaseIconRef(iconRef);
	
	return image;
}

@end
