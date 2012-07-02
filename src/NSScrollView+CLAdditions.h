//
//  NSScrollView+CLAdditions.h
//  Syndication
//
//  Created by Calvin Lough on 3/7/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@interface NSScrollView (CLAdditions)

- (void)ayScrollToTop;
- (void)ayScrollToBottom;
- (void)ayPageUp;
- (void)ayPageDown;
- (void)ayScrollTo:(NSPoint)scrollPoint;
- (void)ayScrollInstantlyTo:(NSPoint)scrollPoint;

@end
