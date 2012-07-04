//
//  NSScrollView+CLAdditions.h
//  Syndication
//
//  Created by Calvin Lough on 3/7/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@interface NSScrollView (CLAdditions)

- (void)clScrollToTop;
- (void)clScrollToBottom;
- (void)clPageUp;
- (void)clPageDown;
- (void)clScrollTo:(NSPoint)scrollPoint;
- (void)clScrollInstantlyTo:(NSPoint)scrollPoint;

@end
