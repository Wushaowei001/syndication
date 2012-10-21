//
//  CLVersionNumberHelper.m
//  Syndication
//
//  Created by Calvin Lough on 6/30/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLVersionNumberHelper.h"

@implementation CLVersionNumberHelper

static BOOL isRunningLionOrNewer;

+ (void)initialize {
	SInt32 majorVersionNumber;
	SInt32 minorVersionNumber;
	
	Gestalt(gestaltSystemVersionMajor, &majorVersionNumber);
	Gestalt(gestaltSystemVersionMinor, &minorVersionNumber);
	
	if ((majorVersionNumber == 10 && minorVersionNumber >= 7) || majorVersionNumber >= 11) {
		isRunningLionOrNewer = YES;
	} else {
		isRunningLionOrNewer = NO;
	}
}

+ (BOOL)isRunningLionOrNewer {
	return isRunningLionOrNewer;
}


@end
