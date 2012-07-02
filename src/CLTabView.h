//
//  CLTabView.h
//  Syndication
//
//  Created by Calvin Lough on 01/14/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLTabViewDelegate.h"

@class CLTabViewItem;

@interface CLTabView : NSView {
	id <CLTabViewDelegate> delegate;
	NSMutableArray *tabViewItems;
	CLTabViewItem *selectedTabViewItem;
	NSView *displayView;
	NSRect addButtonRect;
	BOOL isAddButtonHover;
	CLTabViewItem *dragTabViewItem;
}

@property (assign, nonatomic) id <CLTabViewDelegate> delegate;
@property (retain, nonatomic) NSMutableArray *tabViewItems;
@property (retain, nonatomic) CLTabViewItem *selectedTabViewItem;
@property (assign, nonatomic) IBOutlet NSView *displayView;
@property (assign, nonatomic) NSRect addButtonRect;
@property (assign, nonatomic) BOOL isAddButtonHover;
@property (retain, nonatomic) CLTabViewItem *dragTabViewItem;

@end
