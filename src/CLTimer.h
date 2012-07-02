//
//  CLTimer.h
//  Syndication
//
//  Created by Calvin Lough on 4/18/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@interface CLTimer : NSObject {
	NSTimer *timer;
	NSTimeInterval timeInterval;
	id target;
	SEL selector;
	id userInfo;
	BOOL repeats;
	double startTime;
	NSDate *sleepDate;
}

@property (retain, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSTimeInterval timeInterval;
@property (assign, nonatomic) id target;
@property (assign, nonatomic) SEL selector;
@property (assign, nonatomic) id userInfo;
@property (assign, nonatomic) BOOL repeats;
@property (assign, nonatomic) double startTime;
@property (retain, nonatomic) NSDate *sleepDate;

+ (CLTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)aTimeInterval target:(id)aTarget selector:(SEL)aSelector userInfo:(id)aUserInfo repeats:(BOOL)aRepeats;

- (void)invalidate;
- (BOOL)isValid;
- (void)realTimerFired:(NSTimer *)realTimer;
- (void)willSleep:(NSNotification *)notification;
- (void)didWake:(NSNotification *)notification;
- (void)clockDidChange:(NSNotification *)notification;

@end
