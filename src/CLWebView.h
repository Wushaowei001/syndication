//
//  CLWebView.h
//  Syndication
//
//  Created by Calvin Lough on 2/19/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import <WebKit/WebKit.h>

@class CLTabViewItem;

@interface CLWebView : WebView {
	CLTabViewItem *tabViewItemReference;
}

@property (assign, nonatomic) CLTabViewItem *tabViewItemReference; // weak reference

@end
