//
//  CLTimelineViewItemView.h
//  Syndication
//
//  Created by Calvin Lough on 2/16/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@class CLTimelineViewItem;

@interface CLTimelineViewItemView : NSView {
	CLTimelineViewItem *timelineViewItemReference;
}

@property (assign, nonatomic) CLTimelineViewItem *timelineViewItemReference;

@end
