//
//  CLWebScriptHelper.h
//  Syndication
//
//  Created by Calvin Lough on 3/12/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@class CLWindowController;
@class CLTimelineView;
@class CLTimelineViewItem;

@interface CLWebScriptHelper : NSObject {
	CLWindowController *windowControllerReference;
	CLTimelineView *timelineViewReference;
	CLTimelineViewItem *timelineViewItemReference;
}

@property (assign, nonatomic) CLWindowController *windowControllerReference;
@property (assign, nonatomic) CLTimelineView *timelineViewReference;
@property (assign, nonatomic) CLTimelineViewItem *timelineViewItemReference;

+ (CLWebScriptHelper *)webScriptHelper;

- (void)selectItem;

@end
