//
//  CLOperation.m
//  Syndication
//
//  Created by Calvin Lough on 5/11/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLConstants.h"
#import "CLOperation.h"

@implementation CLOperation

@synthesize _delegate;

- (id <CLOperationDelegate>)delegate {
	return _delegate;
}

- (void)setDelegate:(id <CLOperationDelegate>)delegate {
	[self set_delegate:delegate];
}

- (void)dispatchDidStartDelegateMessage {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	[[self delegate] didStartOperation:self];
}

- (void)dispatchDidFinishDelegateMessage {
	if ([NSThread isMainThread] == NO) {
		CLLog(@"oops, this code should only be run from the main thread!!");
	}
	
	[[self delegate] didFinishOperation:self];
}

@end
