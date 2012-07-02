//
//  CLIconRefreshOperationDelegate.h
//  Syndication
//
//  Created by Calvin Lough on 3/17/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@class CLIconRefreshOperation;
@class CLSourceListFeed;

@protocol CLIconRefreshOperationDelegate <NSObject>

- (void)iconRefreshOperation:(CLIconRefreshOperation *)refreshOp refreshedFeed:(CLSourceListFeed *)feed foundIcon:(NSImage *)icon;

@end
