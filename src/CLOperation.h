//
//  CLOperation.h
//  Syndication
//
//  Created by Calvin Lough on 5/11/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLOperationDelegate.h"

@interface CLOperation : NSOperation {
	id <CLOperationDelegate> _delegate;
}

@property (assign) id <CLOperationDelegate> _delegate;

- (id <CLOperationDelegate>)delegate;
- (void)setDelegate:(id <CLOperationDelegate>)delegate;

- (void)dispatchDidStartDelegateMessage;
- (void)dispatchDidFinishDelegateMessage;

@end
