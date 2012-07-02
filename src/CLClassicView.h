//
//  CLClassicView.h
//  Syndication
//
//  Created by Calvin Lough on 5/2/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import <WebKit/WebKit.h>

@class CLPost;
@class CLTableView;
@class CLTabViewItem;
@class CLWebView;

@interface CLClassicView : NSObject {
	CLTabViewItem *tabViewItemReference;
	NSView *view;
	NSSplitView *splitView;
	CLTableView *tableView;
	CLWebView *webView;
	NSMutableArray *posts;
	NSMutableDictionary *unreadItemsDict;
	BOOL postsMissingFromBottom;
	CLPost *displayedPost;
	WebView *informationWebView;
	BOOL shouldIgnoreSelectionChange;
}

@property (assign, nonatomic) CLTabViewItem *tabViewItemReference;
@property (assign, nonatomic) IBOutlet NSView *view;
@property (assign, nonatomic) IBOutlet NSSplitView *splitView;
@property (assign, nonatomic) IBOutlet CLTableView *tableView;
@property (assign, nonatomic) IBOutlet CLWebView *webView;
@property (retain, nonatomic) NSMutableArray *posts;
@property (retain, nonatomic) NSMutableDictionary *unreadItemsDict;
@property (assign, nonatomic) BOOL postsMissingFromBottom;
@property (retain, nonatomic) CLPost *displayedPost;
@property (assign, nonatomic) WebView *informationWebView;
@property (assign, nonatomic) BOOL shouldIgnoreSelectionChange;

- (void)updateUsingPost:(CLPost *)post headlineFontName:(NSString *)headlineFontName headlineFontSize:(CGFloat)headlineFontSize bodyFontName:(NSString *)bodyFontName bodyFontSize:(CGFloat)bodyFontSize;
- (void)removePostsInRange:(NSRange)range preserveScrollPosition:(BOOL)preserveScroll updateMetadata:(BOOL)updateMetadata ignoreSelection:(BOOL)ignoreSelection;

@end
