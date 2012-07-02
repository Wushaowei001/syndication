//
//  CLTimer.m
//  Syndication
//
//  Created by Calvin Lough on 4/18/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLTimer.h"
#import <QuartzCore/QuartzCore.h>

@implementation CLTimer

@synthesize timer;
@synthesize timeInterval;
@synthesize target;
@synthesize selector;
@synthesize userInfo;
@synthesize repeats;
@synthesize startTime;
@synthesize sleepDate;

- (void)dealloc {
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[timer release];
	[sleepDate release];
	
	[super dealloc];
}

+ (CLTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)aTimeInterval target:(id)aTarget selector:(SEL)aSelector userInfo:(id)aUserInfo repeats:(BOOL)aRepeats {
	CLTimer *newTimer = [[[CLTimer alloc] init] autorelease];
	[newTimer setTimeInterval:aTimeInterval];
	[newTimer setTarget:aTarget];
	[newTimer setSelector:aSelector];
	[newTimer setUserInfo:aUserInfo];
	[newTimer setRepeats:aRepeats];
	[newTimer setStartTime:CACurrentMediaTime()];
	
	NSTimer *realTimer = [NSTimer scheduledTimerWithTimeInterval:aTimeInterval target:newTimer selector:@selector(realTimerFired:) userInfo:nil repeats:aRepeats];
	[newTimer setTimer:realTimer];
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:newTimer selector:@selector(willSleep:) name:NSWorkspaceWillSleepNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:newTimer selector:@selector(didWake:) name:NSWorkspaceDidWakeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:newTimer selector:@selector(clockDidChange:) name:NSSystemClockDidChangeNotification object:nil];
	
	return newTimer;
}

- (void)invalidate {
	[timer invalidate];
	[self setTimer:nil];
}

- (BOOL)isValid {
	return [timer isValid];
}

- (void)realTimerFired:(NSTimer *)realTimer {
	if (target != nil && selector != nil) {
		if ([target respondsToSelector:selector]) {
			[target performSelector:selector withObject:self];
		}
	}
	
	if ([self repeats] == NO) {
		[self setTimer:nil];
	}
}

- (void)willSleep:(NSNotification *)notification {
	if ([self isValid]) {
		[self setSleepDate:[NSDate date]];
	} else {
		CLLog(@"sleep not valid");
	}
}

- (void)didWake:(NSNotification *)notification {
	if ([self isValid]) {
		if (sleepDate == nil) {
			CLLog(@"sleep date nil");
			return;
		}
		
		NSDate *wakeDate = [NSDate date];
		double currentTime = CACurrentMediaTime();
		NSTimeInterval sleepLength = [wakeDate timeIntervalSinceDate:sleepDate];
		NSTimeInterval adjustedTimeInterval = (timeInterval - (currentTime - startTime)) - sleepLength;
		
		//CLLog(@"wake time: %f", currentTime);
		//CLLog(@"sleep length: %f", sleepLength);
		//CLLog(@"adjusting timer to fire in %f seconds", adjustedTimeInterval);
		
		NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:adjustedTimeInterval];
		[timer setFireDate:fireDate];
		
		[self setSleepDate:nil];
	} else {
		CLLog(@"wake not valid");
	}
}

- (void)clockDidChange:(NSNotification *)notification {
	if ([self isValid]) {
		double currentTime = CACurrentMediaTime();
		NSTimeInterval adjustedTimeInterval = timeInterval - (currentTime - startTime);
		NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:adjustedTimeInterval];
		[timer setFireDate:fireDate];
	} else {
		CLLog(@"clock not valid");
	}
}

@end
