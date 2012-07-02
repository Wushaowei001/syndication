//
//  CLOperationDelegate.h
//  Syndication
//
//  Created by Calvin Lough on 5/11/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@class CLOperation;

@protocol CLOperationDelegate <NSObject>

- (void)didStartOperation:(CLOperation *)op;
- (void)didFinishOperation:(CLOperation *)op;

@end
