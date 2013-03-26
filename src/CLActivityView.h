//
//  CLActivityView.h
//  Syndication
//
//  Created by Calvin Lough on 5/10/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@interface CLActivityView : NSView {
	NSMutableArray *feeds;
	NSProgressIndicator *spinner1;
	NSProgressIndicator *spinner2;
}

@property (retain, nonatomic) NSMutableArray *feeds;
@property (retain, nonatomic) NSProgressIndicator *spinner1;
@property (retain, nonatomic) NSProgressIndicator *spinner2;

@end
