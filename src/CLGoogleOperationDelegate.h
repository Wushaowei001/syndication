//
//  CLGoogleOperationDelegate.h
//  Syndication
//
//  Created by Calvin Lough on 4/6/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLOperationDelegate.h"

@class CLGoogleOperation;

@protocol CLGoogleOperationDelegate <CLOperationDelegate>

- (void)googleOperation:(CLGoogleOperation *)googleOp foundAuthToken:(NSString *)token;
- (void)googleOperation:(CLGoogleOperation *)googleOp handleAuthError:(NSDictionary *)authError;

@end
