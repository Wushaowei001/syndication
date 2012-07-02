//
//  CLTimelineViewItem.h
//  Syndication
//
//  Created by Calvin Lough on 02/08/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@class CLPost;
@class CLTimelineView;
@class CLTimelineViewItemView;
@class CLTimer;
@class CLWebView;

@interface CLTimelineViewItem : NSObject {
	CLTimelineView *timelineViewReference;
	CLTimelineViewItemView *view;
	CLWebView *webView;
	CGFloat height;
	CGFloat heightAtLastUpdate;
	BOOL isNewPost;
	BOOL isSelected;
	BOOL isRead;
	NSInteger postDbId;
	NSInteger feedDbId;
	NSDate *postDate;
	NSString *postUrl;
	CLTimer *heightUpdateTimer;
	NSUInteger heightUpdateCount;
}

@property (assign, nonatomic) CLTimelineView *timelineViewReference;
@property (assign, nonatomic) IBOutlet CLTimelineViewItemView *view;
@property (assign, nonatomic) IBOutlet CLWebView *webView;
@property (assign, nonatomic) CGFloat height;
@property (assign, nonatomic) CGFloat heightAtLastUpdate;
@property (assign, nonatomic) BOOL isNewPost;
@property (assign, nonatomic) BOOL isSelected;
@property (assign, nonatomic) BOOL isRead;
@property (assign, nonatomic) NSInteger postDbId;
@property (assign, nonatomic) NSInteger feedDbId;
@property (retain, nonatomic) NSDate *postDate;
@property (retain, nonatomic) NSString *postUrl;
@property (retain, nonatomic) CLTimer *heightUpdateTimer;
@property (assign, nonatomic) NSUInteger heightUpdateCount;

- (void)updateClassNames;
- (BOOL)updateHeight;
- (void)updateUsingPost:(CLPost *)post headlineFontName:(NSString *)headlineFontName headlineFontSize:(CGFloat)headlineFontSize bodyFontName:(NSString *)bodyFontName bodyFontSize:(CGFloat)bodyFontSize;

@end
