//
//  CLTabViewItemAnimation.h
//  Syndication
//
//  Created by Calvin Lough on 01/22/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@class CLTabViewItem;

@interface CLTabViewItemAnimation : NSAnimation {
	CLTabViewItem *tabViewItemReference;
	NSInteger originalXPosition;
	NSInteger targetXPosition;
}

@property (assign, nonatomic) CLTabViewItem *tabViewItemReference; // weak reference
@property (assign, nonatomic) NSInteger originalXPosition;
@property (assign, nonatomic) NSInteger targetXPosition;

@end
