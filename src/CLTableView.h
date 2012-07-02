//
//  CLTableView.h
//  Syndication
//
//  Created by Calvin Lough on 5/2/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@class CLClassicView;

@interface CLTableView : NSTableView {
	CLClassicView *classicViewReference;
}

@property (assign, nonatomic) CLClassicView *classicViewReference;

@end
