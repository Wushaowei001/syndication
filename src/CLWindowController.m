//
//  CLWindowController.m
//  Syndication
//
//  Created by Calvin Lough on 2/17/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLClassicView.h"
#import "CLConstants.h"
#import "CLDatabaseHelper.h"
#import "CLDateHelper.h"
#import "CLErrorHelper.h"
#import "CLFeedSheetController.h"
#import "CLPost.h"
#import "CLSourceList.h"
#import "CLSourceListFeed.h"
#import "CLSourceListFolder.h"
#import "CLSourceListItem.h"
#import "CLSourceListTextFieldCell.h"
#import "CLTabView.h"
#import "CLTabViewItem.h"
#import "CLTableView.h"
#import "CLTableViewTextFieldCell.h"
#import "CLTimelineView.h"
#import "CLTimelineViewItem.h"
#import "CLTimelineViewItemView.h"
#import "CLTimer.h"
#import "CLVersionNumberHelper.h"
#import "CLWebTab.h"
#import "CLWebTabToolbarView.h"
#import "CLWebView.h"
#import "CLWebScriptHelper.h"
#import "CLWindowController.h"
#import "SyndicationAppDelegate.h"
#import "FMDatabase.h"
#import "GTMNSString+HTML.h"
#import "NSImage+CLAdditions.h"
#import "NSScrollView+CLAdditions.h"
#import "NSString+CLAdditions.h"

#define TAB_BAR_HEIGHT 21
#define MAX_TAB_WIDTH 185
#define DRAG_PADDING 5
#define SOURCE_LIST_DRAG_TYPE @"SourceListDragType"
#define TIMELINE_POSTS_PER_QUERY 3
#define CLASSIC_VIEW_POSTS_PER_QUERY 100
#define SEARCH_QUERY @"SELECT post.*, feed.Title AS FeedTitle, feed.Url AS FeedUrlString FROM post, feed WHERE post.FeedId=feed.Id AND post.IsHidden=0 AND (%@)"
#define FEED_QUERY @"SELECT post.*, feed.Title AS FeedTitle, feed.Url AS FeedUrlString FROM post, feed WHERE post.FeedId=feed.Id AND feed.Id=%ld AND post.IsHidden=0"
#define FOLDER_QUERY @"SELECT post.*, feed.Title AS FeedTitle, feed.Url AS FeedUrlString FROM post, feed, folder WHERE post.FeedId=feed.Id AND feed.FolderId=folder.Id AND folder.Path LIKE '%@%%' AND post.IsHidden=0"
#define NEW_ITEMS_QUERY @"SELECT post.*, feed.Title AS FeedTitle, feed.Url AS FeedUrlString FROM post, feed WHERE post.FeedId=feed.Id AND post.IsHidden=0 AND post.IsRead=0"
#define STARRED_QUERY @"SELECT post.*, feed.Title AS FeedTitle, feed.Url AS FeedUrlString FROM post, feed WHERE post.FeedId=feed.Id AND post.IsHidden=0 AND post.IsStarred=1"

@implementation CLWindowController

@synthesize delegate;
@synthesize viewMode;
@synthesize subscriptionList;
@synthesize sourceList;
@synthesize sourceListRoot;
@synthesize sourceListNewItems;
@synthesize sourceListStarredItems;
@synthesize sourceListSubscriptions;
@synthesize sourceListSelectedItem;
@synthesize tabView;
@synthesize splitView;
@synthesize viewSegmentedControl;
@synthesize addButtonTrackingTag;
@synthesize dragTabIndex;
@synthesize dragTabOriginalX;
@synthesize dragMouseOriginalX;
@synthesize dragShouldStart;
@synthesize dragDelayTimer;
@synthesize feedSheetController;
@synthesize feedSheetTextField;
@synthesize sourceListDragItem;
@synthesize sourceListContextMenu;
@synthesize searchField;
@synthesize classicViewRefreshTimer;
@synthesize activityView;
@synthesize lastClassicViewDividerPosition;
@synthesize lastWindowChange;

- (id)init {
	self = [super initWithWindowNibName:@"CLWindow"];
	if (self != nil) {
		[self setDragTabIndex:-1];
		[self setAddButtonTrackingTag:-1];
		[self setLastClassicViewDividerPosition:-1];
		[self setLastWindowChange:-1];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	if (addButtonTrackingTag != -1) {
		[tabView removeTrackingRect:addButtonTrackingTag];
	}
	
	if (dragDelayTimer != nil) {
		if ([dragDelayTimer isValid]) {
			[dragDelayTimer invalidate];
		}
	}
	
	[sourceList setDelegate:nil];
	[sourceList setDataSource:nil];
	
	for (CLTabViewItem *tabViewItem in [tabView tabViewItems]) {
		if ([tabViewItem tabType] == CLTimelineType) {
			CLTimelineView *timelineView = [tabViewItem timelineView];
			[timelineView removeAllPostsFromTimeline];
		} else if ([tabViewItem tabType] == CLWebType) {
			[self removeViewForWebTab:tabViewItem];
		}
	}
	
	[tabView setDelegate:nil];
	[tabView setTabViewItems:nil];
	
	if (classicViewRefreshTimer != nil) {
		if ([classicViewRefreshTimer isValid]) {
			[classicViewRefreshTimer invalidate];
		}
	}
	
	[subscriptionList release];
	[sourceListRoot release];
	[sourceListNewItems release];
	[sourceListStarredItems release];
	[sourceListSubscriptions release];
	[sourceListSelectedItem release];
	[dragDelayTimer release];
	[classicViewRefreshTimer release];
	
	[super dealloc];
}

- (void)windowDidLoad {
	
	[tabView setDelegate:self];
	[self openNewEmptyTab];
	
	// create an object as a placeholder until we create the real object; crashes otherwise
	[self setSourceListRoot:[[[CLSourceListItem alloc] init] autorelease]];
	
	[sourceList setDelegate:self];
	[sourceList setDataSource:self];
	[sourceList registerForDraggedTypes:[NSArray arrayWithObjects:SOURCE_LIST_DRAG_TYPE, nil]];
	[sourceList setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
	
	[self setupSourceList];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidEndLiveResize:) name:NSWindowDidEndLiveResizeNotification object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clockDidChange:) name:NSSystemClockDidChangeNotification object:nil];
	
	// update source list at midnight (because the date is displayed differently depending on which day it is)
	NSTimeInterval timeUntilMidnight = [CLDateHelper timeIntervalUntilMidnight];
	
	CLTimer *refreshTimer = [CLTimer scheduledTimerWithTimeInterval:(timeUntilMidnight + 1.0) target:self selector:@selector(classicViewRefreshTimerFired:) userInfo:nil repeats:NO];
	[self setClassicViewRefreshTimer:refreshTimer];
}

- (void)updateFirstResponder {
	CLTabViewItem *tabViewItem = [tabView selectedTabViewItem];
	BOOL returnVal = NO;
	
	if (tabViewItem != nil) {
		if ([tabViewItem tabType] == CLTimelineType) {
			if ([[[tabViewItem timelineView] timelineViewItems] count] > 0) {
				returnVal = [[self window] makeFirstResponder:[[tabViewItem timelineView] scrollViewReference]];
			} else {
				returnVal = [[self window] makeFirstResponder:[[tabViewItem timelineView] informationWebView]];
			}
		} else if ([tabViewItem tabType] == CLClassicType) {
			if ([[[tabViewItem classicView] posts] count] > 0) {
				returnVal = [[self window] makeFirstResponder:[[tabViewItem classicView] tableView]];
			} else {
				returnVal = [[self window] makeFirstResponder:[[tabViewItem classicView] informationWebView]];
			}
		} else if ([tabViewItem tabType] == CLWebType) {
			returnVal = [[self window] makeFirstResponder:[[tabViewItem webTab] webView]];
		}
	}
}

- (void)keyDown:(NSEvent *)event {
	
	CLTabViewItem *tabViewItem = [tabView selectedTabViewItem];
	NSString *chars = [event characters];
	unichar character = [chars characterAtIndex:0];
	BOOL shiftIsPressed = (([event modifierFlags] & NSShiftKeyMask) > 0);
	
	if (tabViewItem != nil) {
		NSScrollView *scrollView = nil;
		BOOL scrollDidChange = NO;
		
		if ([tabViewItem tabType] == CLTimelineType) {
			CLTimelineView *timelineView = [tabViewItem timelineView];
			scrollView = [timelineView scrollViewReference];
			
			if (character == CLSpaceCharacter) {
				
				if (shiftIsPressed) {
					[scrollView clPageUp];
				} else {
					[scrollView clPageDown];
				}
				
				scrollDidChange = YES;
			} else if (character == NSHomeFunctionKey) {
				[scrollView clScrollToTop];
				scrollDidChange = YES;
			} else if (character == NSEndFunctionKey) {
				[scrollView clScrollToBottom];
				scrollDidChange = YES;
			} else if (character == NSUpArrowFunctionKey) {
				[self selectPreviousItemForTimelineView:timelineView];
			} else if (character == NSDownArrowFunctionKey) {
				[self selectNextItemForTimelineView:timelineView];
			}
			
			if (scrollDidChange) {
				[self checkIfTimelineNeedsToUnloadContent:timelineView];
				[self checkIfTimelineNeedsToLoadMoreContent:timelineView];
			}
		}
	}
}

- (void)setupSourceList {
	
	CLSourceListItem *root = [[CLSourceListItem alloc] init];
	
	CLSourceListItem *library = [[CLSourceListItem alloc] init];
	[library setTitle:@"LIBRARY"];
	[library setIsGroupItem:YES];
	
	CLSourceListItem *newItems = [[CLSourceListItem alloc] init];
	[newItems setTitle:@"New Items"];
	
	NSString *newItemsIconName = [[NSBundle mainBundle] pathForResource:@"inbox-table" ofType:@"png"];
	NSImage *newItemsIcon = [[[NSImage alloc] initWithContentsOfFile:newItemsIconName] autorelease];
	[newItemsIcon setFlipped:YES];
	[newItems setIcon:newItemsIcon];
	
	[[library children] addObject:newItems];
	[self setSourceListNewItems:newItems];
	[newItems release];
	
	CLSourceListItem *starredItems = [[CLSourceListItem alloc] init];
	[starredItems setTitle:@"Starred Items"];
	
	NSImage *starredItemsIcon = [NSImage imageNamed:@"star"];
	[starredItemsIcon setFlipped:YES];
	[starredItems setIcon:starredItemsIcon];
	
	[[library children] addObject:starredItems];
	[self setSourceListStarredItems:starredItems];
	[starredItems release];
	
	[[root children] addObject:library];
	[library release];
	
	CLSourceListItem *subscriptions = [[CLSourceListItem alloc] init];
	[subscriptions setTitle:@"SUBSCRIPTIONS"];
	[subscriptions setIsGroupItem:YES];
	
	[subscriptions setChildren:subscriptionList];
	
	[[root children] addObject:subscriptions];
	[self setSourceListSubscriptions:subscriptions];
	[subscriptions release];
	
	[self setSourceListRoot:root];
	[root release];
	
	[sourceList reloadData];
	
	// expand group items
	CLSourceListItem *child;
	
	for (NSUInteger i=0; i<[[sourceListRoot children] count]; i++) {
		child = [[sourceListRoot children] objectAtIndex:i];
		if ([sourceList isExpandable:child]) {
			[sourceList expandItem:child];
		}
	}
}

- (void)refreshSourceList {
	[sourceList reloadData];
	[sourceList setNeedsDisplay:YES];
}

- (NSInteger)updateBadgeValuesFor:(NSMutableArray *)children {
	NSInteger unreadCount = 0;
	
	for (CLSourceListItem *subscription in children) {
		if ([subscription isKindOfClass:[CLSourceListFeed class]]) {
			unreadCount += [subscription badgeValue];
		} else if ([subscription isKindOfClass:[CLSourceListFolder class]]) {
			CLSourceListFolder *folder = (CLSourceListFolder *)subscription;
			NSUInteger folderUnread = 0;
			
			folderUnread += [self updateBadgeValuesFor:[folder children]];
			
			[folder setBadgeValue:folderUnread];
			unreadCount += folderUnread;
		}
	}
	
	return unreadCount;
}

- (void)refreshTabsForAncestorsOf:(CLSourceListItem *)item {
	CLSourceListFolder *ancestor = nil;
	
	if ([item isKindOfClass:[CLSourceListFeed class]]) {
		ancestor = [(CLSourceListFeed *)item enclosingFolderReference];
	} else if ([item isKindOfClass:[CLSourceListFolder class]]) {
		ancestor = [(CLSourceListFolder *)item parentFolderReference];
	}
	
	if (ancestor != nil) {
		for (CLTabViewItem *tabViewItem in [tabView tabViewItems]) {
			if ([tabViewItem sourceListItem] == ancestor) {
				[self reloadContentForTab:tabViewItem];
			}
		}
		
		[self refreshTabsForAncestorsOf:ancestor];
	}
}

- (void)refreshTabsFor:(CLSourceListItem *)item {
	if (item != nil) {
		for (CLTabViewItem *tabViewItem in [tabView tabViewItems]) {
			if ([tabViewItem sourceListItem] == item) {
				[self reloadContentForTab:tabViewItem];
			}
		}
	}
}

- (void)refreshSearchTabs {
	for (CLTabViewItem *tabViewItem in [tabView tabViewItems]) {
		if ([tabViewItem sourceListItem] == nil && [tabViewItem searchQuery] != nil) {
			[self reloadContentForTab:tabViewItem];
		}
	}
}

- (void)loadPostsIntoTimeline:(CLTimelineView *)timeline orClassicView:(CLClassicView *)classicView {
	NSRange range = NSMakeRange(0, 0);
	
	if (timeline != nil) {
		range = NSMakeRange([[timeline timelineViewItems] count], TIMELINE_POSTS_PER_QUERY);
	} else if (classicView != nil) {
		range = NSMakeRange([[classicView posts] count], CLASSIC_VIEW_POSTS_PER_QUERY);
	}
	
	[self loadPostsIntoTimeline:timeline orClassicView:classicView fromRange:range atBottom:YES];
}

- (void)loadPostsIntoTimeline:(CLTimelineView *)timeline orClassicView:(CLClassicView *)classicView fromRange:(NSRange)range atBottom:(BOOL)bottom {
	
	if (timeline == nil && classicView == nil) {
		return;
	}
	
	if (range.length == 0) {
		return;
	}
	
	CLTabViewItem *tabViewItem = nil;
	
	if (timeline != nil) {
		tabViewItem = [timeline tabViewItemReference];
	} else if (classicView != nil) {
		tabViewItem = [classicView tabViewItemReference];
	}
	
	CLSourceListItem *sourceListItem = [tabViewItem sourceListItem];
	NSString *searchQuery = [tabViewItem searchQuery];
	
	if (sourceListItem == nil && searchQuery == nil) {
		return;
	}
	
	FMDatabase *db = [FMDatabase databaseWithPath:[CLDatabaseHelper pathForDatabaseFile]];
	
	if (![db open]) {
		[NSException raise:@"Database error" format:@"Failed to connect to the database!"];
	}
	
	NSMutableString *dbQuery = [NSMutableString string];
	
	if (searchQuery != nil) {
		NSArray *queryParts = [searchQuery componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		NSMutableString *queryBuild = [NSMutableString string];
		BOOL isFirst = YES;
		
		for (NSString *queryPart in queryParts) {
			if (isFirst == NO) {
				[queryBuild appendString:@" OR "];
			}
			
			[queryBuild appendFormat:@"post.Title LIKE '%%%@%%'", queryPart];
			[queryBuild appendFormat:@" OR post.Author LIKE '%%%@%%'", queryPart];
			[queryBuild appendFormat:@" OR post.PlainTextContent LIKE '%%%@%%'", queryPart];
			[queryBuild appendFormat:@" OR feed.Title LIKE '%%%@%%'", queryPart];
			
			isFirst = NO;
		}
		
		[dbQuery appendFormat:SEARCH_QUERY, queryBuild];
	} else if ([sourceListItem isKindOfClass:[CLSourceListFeed class]]) {
		[dbQuery appendFormat:FEED_QUERY, [(CLSourceListFeed *)sourceListItem dbId]];
	} else if ([sourceListItem isKindOfClass:[CLSourceListFolder class]]) {
		[dbQuery appendFormat:FOLDER_QUERY, [(CLSourceListFolder *)sourceListItem path]];
	} else if (sourceListItem == sourceListNewItems) {
		[dbQuery appendString:NEW_ITEMS_QUERY];
	} else if (sourceListItem == sourceListStarredItems) {
		[dbQuery appendString:STARRED_QUERY];
	} else {
		return;
	}
	
	BOOL isOnlyUnreadItems = NO;
	
	if (sourceListItem == sourceListNewItems) {
		isOnlyUnreadItems = YES;
	}
	
	[dbQuery appendString:@" ORDER BY post.Id DESC"];
	
	if (timeline != nil) {
		if (bottom) {
			if (isOnlyUnreadItems) {
				NSInteger numberOfReadPosts = 0;
				
				for (CLTimelineViewItem *timelineViewItem in [timeline timelineViewItems]) {
					if ([timelineViewItem isRead]) {
						numberOfReadPosts++;
					}
				}
				
				[dbQuery appendFormat:@" LIMIT %ld, %ld", (range.location + [timeline postsMissingFromTopCount] - numberOfReadPosts), range.length];
			} else {
				[dbQuery appendFormat:@" LIMIT %ld, %ld", (range.location + [timeline postsMissingFromTopCount]), range.length];
			}
		} else {
			[dbQuery appendFormat:@" LIMIT %ld, %ld", ((range.location + [timeline postsMissingFromTopCount]) - range.length), range.length];
		}
	} else {
		if (isOnlyUnreadItems) {
			NSInteger numberOfReadPosts = 0;
			
			for (CLPost *post in [classicView posts]) {
				if ([post isRead]) {
					numberOfReadPosts++;
				}
			}
			
			[dbQuery appendFormat:@" LIMIT %ld, %ld", (range.location - numberOfReadPosts), range.length];
		} else {
			[dbQuery appendFormat:@" LIMIT %ld, %ld", range.location, range.length];
		}
	}
	
	FMResultSet *rs = [db executeQuery:dbQuery];
	NSMutableArray *posts = [NSMutableArray array];
	
	while ([rs next]) {
		CLPost *post = [[CLPost alloc] initWithResultSet:rs];
		
		if ([rs boolForColumn:@"HasEnclosures"]) {
			FMResultSet *rs2 = [db executeQuery:@"SELECT * FROM enclosure WHERE PostId=?", [NSNumber numberWithInteger:[post dbId]]];
			
			while ([rs2 next]) {
				[[post enclosures] addObject:[rs2 stringForColumn:@"Url"]];
			}
			
			[rs2 close];
		}
		
		[posts addObject:post];
		[post release];
	}
	
	[rs close];
	[db close];
	
	NSInteger i = 0;
	
	for (CLPost *post in posts) {
		
		if (timeline != nil) {
			if (bottom) {
				[self addPost:post toTimeline:timeline atIndex:NSNotFound];
			} else {
				[self addPost:post toTimeline:timeline atIndex:(range.location + i)];
			}
			
		} else if (classicView != nil) {
			[[classicView posts] addObject:post];
			
			if ([post isRead] == NO) {
				NSNumber *key = [NSNumber numberWithInteger:[post dbId]];
				[[classicView unreadItemsDict] setObject:post forKey:key];
			}
		}
		
		i++;
	}
	
	NSUInteger numPostsRequested = (NSInteger)range.length;
	
	if (timeline != nil) {
		
		if (bottom == NO) {
			
			[timeline setPostsMissingFromTopCount:([timeline postsMissingFromTopCount] - numPostsRequested)];
			
			if ([timeline postsMissingFromTopCount] < 0) {
				[timeline setPostsMissingFromTopCount:0];
			}
			
		} else {
			
			// if the query returned less posts than we asked for, it doesn't have any more left, so remember this
			if ([posts count] < numPostsRequested) {
				[timeline setPostsMissingFromBottom:NO];
			}
		}
		
		if ([timeline postsMissingFromTopCount] > 0 || [timeline postsMissingFromBottom]) {
			[self performSelector:@selector(checkIfTimelineNeedsToLoadMoreContent:) withObject:timeline afterDelay:0.25];
		}
		
		if ([[timeline timelineViewItems] count] > 0) {
			[timeline updateSubviewRects];
			[timeline setNeedsDisplay:YES];
		}
		
	} else if (classicView != nil) {
		
		if ([posts count] < numPostsRequested) {
			[classicView setPostsMissingFromBottom:NO];
		}
		
		if ([classicView postsMissingFromBottom]) {
			[self performSelector:@selector(checkIfClassicViewNeedsToLoadMoreContent:) withObject:classicView afterDelay:1];
		}
		
		if ([[classicView posts] count] > 0) {
			[[classicView tableView] reloadData];
		}
	}
	
	[self updateViewVisibilityForTab:tabViewItem];
}

- (void)addPost:(CLPost *)post toTimeline:(CLTimelineView *)timeline atIndex:(NSInteger)indexLoc {
	
	CLTimelineViewItem *item = [[CLTimelineViewItem alloc] init];
	[item setTimelineViewReference:timeline];
	[item setPostDbId:[post dbId]];
	[item setFeedDbId:[post feedDbId]];
	[item setPostDate:[post received]];
	[item setPostUrl:[post link]];
	[item setIsRead:[post isRead]];
	
	[[item webView] setTabViewItemReference:[timeline tabViewItemReference]];
	[[item webView] setPolicyDelegate:self];
	[[item webView] setFrameLoadDelegate:self];
	[[item webView] setUIDelegate:self];
	
	NSString *headlineFontName = [delegate preferenceHeadlineFontName];
	CGFloat headlineFontSize = [delegate preferenceHeadlineFontSize];
	NSString *bodyFontName = [delegate preferenceBodyFontName];
	CGFloat bodyFontSize = [delegate preferenceBodyFontSize];
	
	[item updateUsingPost:post headlineFontName:headlineFontName headlineFontSize:headlineFontSize bodyFontName:bodyFontName bodyFontSize:bodyFontSize];
	
	[[item view] setFrame:NSMakeRect(0, 0, [timeline frame].size.width, 0)];
	
	[timeline addSubview:[item view]];
	
	if (indexLoc == NSNotFound) {
		[[timeline timelineViewItems] addObject:item];
	} else {
		[[timeline timelineViewItems] insertObject:item atIndex:indexLoc];
	}
	
	if ([item isRead] == NO) {
		[SyndicationAppDelegate addToTimelineUnreadItemsDict:item];
	}
	
	[item release];
}

- (IBAction)addSubscription:(id)sender {
	[feedSheetTextField setStringValue:@""];
	[feedSheetController showSheet:self];
}

- (IBAction)doAddNewSubscription:(id)sender {
	NSString *url = [feedSheetTextField stringValue];
	
	if (url != nil && [url length] > 0) {
		[self addSubscriptionForUrlString:url];
	}

	[feedSheetController hideSheet:nil];
}

- (IBAction)addFolder:(id)sender {
	[delegate addFolderWithTitle:nil toFolder:nil forWindow:self];
}

- (void)back {
	CLTabViewItem *selectedTab = [tabView selectedTabViewItem];
	
	if (selectedTab != nil) {
		if ([selectedTab tabType] == CLWebType) {
			CLWebTab *webTab = [selectedTab webTab];
			
			if (webTab != nil) {
				CLWebView *webView = [webTab webView];
				
				if (webView != nil) {
					[webView goBack];
				}
			}
		}
	}
}

- (void)forward {
	CLTabViewItem *selectedTab = [tabView selectedTabViewItem];
	
	if (selectedTab != nil) {
		if ([selectedTab tabType] == CLWebType) {
			CLWebTab *webTab = [selectedTab webTab];
			
			if (webTab != nil) {
				CLWebView *webView = [webTab webView];
				
				if (webView != nil) {
					[webView goForward];
				}
			}
		}
	}
}

- (IBAction)refresh:(id)sender {
	[delegate queueAllFeedsSyncRequest];
}

- (IBAction)view:(id)sender {
	NSInteger clickedSegment = [sender selectedSegment];
	NSInteger clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	
	if (clickedSegmentTag == 0) {
		[self changeToTimelineViewMode];
	} else if (clickedSegmentTag == 1) {
		[self changeToClassicViewMode];
	}
}

- (void)changeToClassicViewMode {
	[self setViewMode:CLClassicViewMode];
	[viewSegmentedControl setSelectedSegment:1];
	[SyndicationAppDelegate miscellaneousSetValue:[[NSNumber numberWithInteger:viewMode] stringValue] forKey:MISCELLANEOUS_VIEW_MODE];
	
	CLTabViewItem *selectedTabViewItem = [tabView selectedTabViewItem];
	
	if (selectedTabViewItem != nil && [selectedTabViewItem tabType] == CLTimelineType) {
		
		CLTimelineView *timelineView = [selectedTabViewItem timelineView];
		
		NSInteger dividerPosition = 210;
		
		if (lastClassicViewDividerPosition >= 0) {
			dividerPosition = lastClassicViewDividerPosition;
		} else {
			NSString *dividerPositionString = [SyndicationAppDelegate miscellaneousValueForKey:MISCELLANEOUS_CLASSIC_VIEW_DIVIDER_POSITION];
			
			if (dividerPositionString != nil) {
				dividerPosition = [dividerPositionString integerValue];
			}
		}
		
		// change other tabs too
		for (CLTabViewItem *tabViewItem in [tabView tabViewItems]) {
			if (tabViewItem != selectedTabViewItem && [tabViewItem tabType] == CLTimelineType) {
				[self openInTab:tabViewItem item:[tabViewItem sourceListItem] orQuery:[tabViewItem searchQuery]];
				[[[tabViewItem classicView] splitView] setPosition:dividerPosition ofDividerAtIndex:0];
			}
		}
		
		NSInteger windowChange = (dividerPosition - VIEW_SWITCH_BUFFER);
		
		if (windowChange < 0) {
			windowChange = 0;
		}
		
		[[timelineView scrollViewReference] setHidden:YES];
		[[timelineView informationWebView] setHidden:YES];
		[self changeWidthOfWindowBy:windowChange];
		[self openItemInCurrentTab:[selectedTabViewItem sourceListItem] orQuery:[selectedTabViewItem searchQuery]];
		[[[selectedTabViewItem classicView] splitView] setPosition:dividerPosition ofDividerAtIndex:0];
	}
}

- (void)changeToTimelineViewMode {
	[self setViewMode:CLTimelineViewMode];
	[viewSegmentedControl setSelectedSegment:0];
	[SyndicationAppDelegate miscellaneousSetValue:[[NSNumber numberWithInteger:viewMode] stringValue] forKey:MISCELLANEOUS_VIEW_MODE];
	
	CLTabViewItem *selectedTabViewItem = [tabView selectedTabViewItem];
	
	if (selectedTabViewItem != nil && [selectedTabViewItem tabType] == CLClassicType) {
		
		CLClassicView *classicView = [selectedTabViewItem classicView];
		
		NSInteger dividerPosition = [[[[classicView splitView] subviews] objectAtIndex:0] frame].size.width;
		
		[self setLastClassicViewDividerPosition:dividerPosition];
		
		NSString *dividerPositionString = [[NSNumber numberWithInteger:dividerPosition] stringValue];
		[SyndicationAppDelegate miscellaneousSetValue:dividerPositionString forKey:MISCELLANEOUS_CLASSIC_VIEW_DIVIDER_POSITION];
		
		NSInteger windowChange;
		
		if (lastWindowChange >= 0) {
			windowChange = lastWindowChange;
		} else {
			windowChange = (dividerPosition - VIEW_SWITCH_BUFFER);
		}
		
		if (windowChange < 0) {
			windowChange = 0;
		}
		
		[[classicView view] setHidden:YES];
		[[classicView informationWebView] setHidden:YES];
		[[self window] makeFirstResponder:[[self window] contentView]];
		[self changeWidthOfWindowBy:(windowChange * -1)];
		[self openItemInCurrentTab:[selectedTabViewItem sourceListItem] orQuery:[selectedTabViewItem searchQuery]];
		
		// change other tabs too
		for (CLTabViewItem *tabViewItem in [tabView tabViewItems]) {
			if (tabViewItem != selectedTabViewItem && [tabViewItem tabType] == CLClassicType) {
				[self openInTab:tabViewItem item:[tabViewItem sourceListItem] orQuery:[tabViewItem searchQuery]];
			}
		}
	}
	
	[[tabView displayView] setNeedsDisplay:YES];
}

- (void)changeWidthOfWindowBy:(NSInteger)change {
	if (change % 2) {
		change++;
	}
	
	NSRect oldFrame = [[self window] frame];
	NSRect newFrame = NSMakeRect(oldFrame.origin.x - (NSInteger)(change / 2), oldFrame.origin.y, oldFrame.size.width + change, oldFrame.size.height);
	NSRect maxFrame = [[NSScreen mainScreen] visibleFrame];
	
	if (newFrame.size.width > maxFrame.size.width) {
		newFrame.size.width = maxFrame.size.width;
	}
	
	if (newFrame.origin.x < maxFrame.origin.x) {
		newFrame.origin.x = maxFrame.origin.x;
	}
	
	if ((newFrame.origin.x + newFrame.size.width) > (maxFrame.origin.x + maxFrame.size.width)) {
		newFrame.origin.x -= ((newFrame.origin.x + newFrame.size.width) - (maxFrame.origin.x + maxFrame.size.width));
	}
	
	NSInteger actualChange = (newFrame.size.width - oldFrame.size.width);
	
	if (actualChange >= 0) {
		[self setLastWindowChange:actualChange];
	}
	
	[[self window] setFrame:newFrame display:YES animate:YES];
}

- (IBAction)search:(id)sender {
	NSString *query = [searchField stringValue];
	
	if (query != nil && [query length] > 0) {
		query = [query clTrimmedString];
		
		[self openItemInCurrentTab:nil orQuery:query];
		[sourceList deselectAll:self];
	}
}

- (void)addSubscriptionForUrlString:(NSString *)url {
	url = [url clTrimmedString];
	
	// add http:// to the beginning if necessary
	NSURL *urlTest = [NSURL URLWithString:url];
	
	if ([urlTest scheme] == nil) {
		NSString *newUrl = [NSString stringWithFormat:@"http://%@", url];
		NSURL *newUrlTest = [NSURL URLWithString:newUrl];
		
		if (newUrlTest != nil && [[newUrlTest scheme] isEqual:@"http"]) {
			url = newUrl;
		}
	}
	
	// check to see if this feed already exists in the database
	FMDatabase *db = [FMDatabase databaseWithPath:[CLDatabaseHelper pathForDatabaseFile]];
	
	if (![db open]) {
		[CLErrorHelper createAndDisplayError:@"Unable to add subscription!"];
		return;
	}
	
	FMResultSet *rs = [db executeQuery:@"SELECT * FROM feed WHERE Url=? AND IsHidden=0", url];
	
	if ([rs next]) {
		[CLErrorHelper createAndDisplayError:@"The subscription could not be added because it already exists in your library!"];
		[rs close];
		[db close];
		return;
	}
	
	[rs close];
	[db close];
	
	[delegate addSubscriptionForUrlString:url withTitle:nil toFolder:nil refreshImmediately:YES];
}

- (BOOL)selectSourceListItem:(CLSourceListItem *)item {
	
	if (item == nil) {
		[sourceList deselectAll:self];
		return YES;
	}
	
	NSInteger rowForItem = [sourceList rowForItem:item];
	
	if (rowForItem != -1) {
		[sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex:rowForItem] byExtendingSelection:NO];
		return YES;
	}
	
	return NO;
}

- (void)editSourceListItem:(CLSourceListItem *)item {
	if (item == nil) {
		return;
	}
	
	NSInteger rowToEdit = [sourceList rowForItem:item];
	[sourceList editColumn:0 row:rowToEdit withEvent:nil select:YES];
}

- (void)redrawSourceListItem:(CLSourceListItem *)item {
	NSInteger itemRow = [sourceList rowForItem:item];
	
	if (itemRow >= 0) {
		[sourceList setNeedsDisplayInRect:[sourceList frameOfCellAtColumn:0 row:itemRow]];
	}
}

- (void)timelineView:(CLTimelineView *)timelineView timelineViewItem:(CLTimelineViewItem *)timelineViewItem scrollToAnchor:(NSString *)anchor {
	CGFloat anchorYPosition = [self yPositionOfAnchor:anchor inWebView:[timelineViewItem webView]];
	
	if (anchorYPosition > 0) {
		CGFloat scrollYPosition = [[timelineViewItem view] frame].origin.y + anchorYPosition;
		CGFloat buffer = 3.0;
		
		// move it up a few pixels just so it looks nice
		if (scrollYPosition > buffer) {
			scrollYPosition = scrollYPosition - buffer;
		}
		
		[[timelineView scrollViewReference] clScrollInstantlyTo:NSMakePoint(0.0, scrollYPosition)];
	}
}

- (void)classicView:(CLClassicView *)classicView scrollToAnchor:(NSString *)anchor {
	CGFloat anchorYPosition = [self yPositionOfAnchor:anchor inWebView:[classicView webView]];
	
	if (anchorYPosition > 0) {
		CGFloat scrollYPosition = anchorYPosition;
		CGFloat buffer = 3.0;
		
		// move it up a few pixels just so it looks nice
		if (scrollYPosition > buffer) {
			scrollYPosition = scrollYPosition - buffer;
		}
		
		NSPoint scrollPoint = NSMakePoint(0.0, scrollYPosition);
		
		NSScrollView *scrollView = [[[[[classicView webView] mainFrame] frameView] documentView] enclosingScrollView];
		[scrollView clScrollInstantlyTo:scrollPoint];
	}
}

- (CGFloat)yPositionOfAnchor:(NSString *)anchor inWebView:(CLWebView *)webView {
	return [[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"function findPos(obj) {var curtop = 0; if (obj.offsetParent) { do { curtop += obj.offsetTop; } while (obj = obj.offsetParent); } return curtop; } findPos(document.getElementById('%@'))", anchor]] doubleValue];
}

- (void)updateWindowTitle {
	NSWindow *window = [self window];
	CLTabViewItem *selectedTabViewItem = [tabView selectedTabViewItem];
	
	if (selectedTabViewItem == nil || [selectedTabViewItem label] == nil || [[selectedTabViewItem label] length] == 0) {
		[window setTitle:@"Syndication"];
	} else {
		[window setTitle:[selectedTabViewItem label]];
	}
}

- (void)updateViewSwitchEnabled {
	[viewSegmentedControl setEnabled:NO forSegment:0];
	[viewSegmentedControl setEnabled:NO forSegment:1];
	
	CLTabViewItem *tabViewItem = [tabView selectedTabViewItem];
	
	if (tabViewItem != nil) {
		if ([tabViewItem tabType] != CLWebType) {
			[viewSegmentedControl setEnabled:YES forSegment:0];
			[viewSegmentedControl setEnabled:YES forSegment:1];
		}
	}
}

- (void)classicViewRefreshTimerFired:(CLTimer *)theTimer {
	
	for (CLTabViewItem *tabViewItem in [tabView tabViewItems]) {
		if ([tabViewItem tabType] == CLClassicType) {
			[[[tabViewItem classicView] tableView] setNeedsDisplay:YES];
		}
	}
	
	NSTimeInterval timeUntilMidnight = [CLDateHelper timeIntervalUntilMidnight];
	
	CLTimer *refreshTimer = [CLTimer scheduledTimerWithTimeInterval:(timeUntilMidnight + 1.0) target:self selector:@selector(classicViewRefreshTimerFired:) userInfo:nil repeats:NO];
	[self setClassicViewRefreshTimer:refreshTimer];
}

- (void)clockDidChange:(NSNotification *)notification {
	for (CLTabViewItem *tabViewItem in [tabView tabViewItems]) {
		if ([tabViewItem tabType] == CLClassicType) {
			[[[tabViewItem classicView] tableView] setNeedsDisplay:YES];
		}
	}
}


#pragma mark source list context menu

- (void)menuNeedsUpdate:(NSMenu *)menu {
	
	if (menu == sourceListContextMenu) {
		NSInteger clickedRow = [sourceList clickedRow];
		CLSourceListItem *clickedItem = [sourceList itemAtRow:clickedRow];
		
		[menu removeAllItems];
		
		if ([clickedItem isGroupItem]) {
			return;
		}
		
		NSMenuItem *openTabItem = [[NSMenuItem alloc] initWithTitle:@"Open in New Tab" action:@selector(sourceListOpenInNewTab:) keyEquivalent:@""];
		[menu addItem:openTabItem];
		[openTabItem release];
		
		NSMenuItem *openWindowItem = [[NSMenuItem alloc] initWithTitle:@"Open in New Window" action:@selector(sourceListOpenInNewWindow:) keyEquivalent:@""];
		[menu addItem:openWindowItem];
		[openWindowItem release];
		
		[menu addItem:[NSMenuItem separatorItem]];
		
		NSMenuItem *refreshItem = [[NSMenuItem alloc] initWithTitle:@"Refresh" action:@selector(sourceListRefresh:) keyEquivalent:@""];
		[menu addItem:refreshItem];
		[refreshItem release];
		
		NSMenuItem *markReadItem = [[NSMenuItem alloc] initWithTitle:@"Mark All As Read" action:@selector(sourceListMarkAllAsRead:) keyEquivalent:@""];
		[menu addItem:markReadItem];
		[markReadItem release];
		
		if ([clickedItem isEditable]) {
			[menu addItem:[NSMenuItem separatorItem]];
			
			NSString *renameTitle;
			
			if ([clickedItem title] != nil && [[clickedItem title] length] > 0) {
				renameTitle = [NSString stringWithFormat:@"Rename \"%@\"", [clickedItem title]];
			} else {
				renameTitle = @"Rename";
			}
			
			NSMenuItem *renameItem = [[NSMenuItem alloc] initWithTitle:renameTitle action:@selector(sourceListRename:) keyEquivalent:@""];
			[menu addItem:renameItem];
			[renameItem release];
			
			NSMenuItem *deleteItem = [[NSMenuItem alloc] initWithTitle:@"Delete..." action:@selector(sourceListDelete:) keyEquivalent:@""];
			[menu addItem:deleteItem];
			[deleteItem release];
		}
	}
}

- (void)sourceListOpenInNewTab:(NSMenuItem *)sender {
	NSInteger clickedRow = [sourceList clickedRow];
	CLSourceListItem *clickedItem = [sourceList itemAtRow:clickedRow];
	[self openNewTabFor:clickedItem selectTab:YES];
}

- (void)sourceListOpenInNewWindow:(NSMenuItem *)sender {
	NSInteger clickedRow = [sourceList clickedRow];
	CLSourceListItem *clickedItem = [sourceList itemAtRow:clickedRow];
	
	if (clickedItem == sourceListNewItems) {
		[delegate newWindow];
	} else if (clickedItem == sourceListStarredItems) {
		CLWindowController *windowController = [delegate newWindow];
		[windowController selectSourceListItem:[windowController sourceListStarredItems]];
	} else {
		[delegate openNewWindowForSubscription:clickedItem];
	}
}

- (void)sourceListRefresh:(NSMenuItem *)sender {
	NSInteger clickedRow = [sourceList clickedRow];
	CLSourceListItem *clickedItem = [sourceList itemAtRow:clickedRow];
	
	if (clickedItem == sourceListNewItems) {
		[delegate queueAllFeedsSyncRequest];
	} else if (clickedItem == sourceListStarredItems) {
		
	} else {
		[delegate refreshSourceListItem:clickedItem];
	}
}

- (void)sourceListMarkAllAsRead:(NSMenuItem *)sender {
	NSInteger clickedRow = [sourceList clickedRow];
	CLSourceListItem *clickedItem = [sourceList itemAtRow:clickedRow];
	
	if (clickedItem == sourceListNewItems) {
		[delegate markAllAsReadForSourceListItem:nil orNewItems:YES orStarredItems:NO orPostsOlderThan:nil];
	} else if (clickedItem == sourceListStarredItems) {
		[delegate markAllAsReadForSourceListItem:nil orNewItems:NO orStarredItems:YES orPostsOlderThan:nil];
	} else {
		[delegate markAllAsReadForSourceListItem:clickedItem orNewItems:NO orStarredItems:NO orPostsOlderThan:nil];
	}
}

- (void)sourceListRename:(NSMenuItem *)sender {
	NSInteger clickedRow = [sourceList clickedRow];
	CLSourceListItem *clickedItem = [sourceList itemAtRow:clickedRow];
	[self editSourceListItem:clickedItem];
}

- (void)sourceListDelete:(NSMenuItem *)sender {
	NSInteger clickedRow = [sourceList clickedRow];
	CLSourceListItem *clickedItem = [sourceList itemAtRow:clickedRow];
	
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	
	if ([clickedItem title] != nil && [[clickedItem title] length] > 0) {
		[alert setMessageText:[NSString stringWithFormat:@"Are you sure you want to delete \"%@\"?", [clickedItem title]]];
	} else if ([clickedItem isKindOfClass:[CLSourceListFeed class]]) {
		[alert setMessageText:@"Are you sure you want to delete this subscription?"];
	} else if ([clickedItem isKindOfClass:[CLSourceListFolder class]]) {
		[alert setMessageText:@"Are you sure you want to delete this folder?"];
	} else { // should never happen, but handle it anyway
		[alert setMessageText:@"Are you sure you want to delete this?"];
	}
	
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(sourceListDeleteAlertDidEnd:returnCode:contextInfo:) contextInfo:clickedItem];
	[alert release];
}

- (void)sourceListDeleteAlertDidEnd:(NSAlert *)theAlert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	
	if (returnCode == NSAlertFirstButtonReturn) {
		
		CLSourceListItem *clickedItem = [(CLSourceListItem *)contextInfo retain];
		
		[delegate deleteSourceListItem:clickedItem];
		
		[clickedItem release];
	}
}


# pragma mark CLSourceList data source methods

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(CLSourceListItem *)item {
    return (item == nil) ? [[sourceListRoot children] count] : [[item children] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(CLSourceListItem *)item {
    return (item == nil) ? YES : ([item isGroupItem] || [item isKindOfClass:[CLSourceListFolder class]] || [[item children] count] > 0);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)childIndex ofItem:(CLSourceListItem *)item {
    return (item == nil) ? [[sourceListRoot children] objectAtIndex:childIndex] : [[item children] objectAtIndex:childIndex];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(CLSourceListItem *)item {
	if (item == nil) {
		return @"";
	}
	
	return [item extractTitleForDisplay];
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(NSString *)value forTableColumn:(NSTableColumn *)tableColumn byItem:(CLSourceListItem *)item {
	
	[item setTitle:value];
	
	[self performSelector:@selector(updateFirstResponder) withObject:nil afterDelay:0.1];
	
	[delegate sourceListDidRenameItem:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
	
	// instead of actually putting the item on the pasteboard, just put it in a ivar
	// seems like a hack, but this is what the apple sample project that I downloaded does
	sourceListDragItem = (CLSourceListItem *)[items objectAtIndex:0];
	
	if ([sourceListDragItem isDraggable] == NO) {
		return NO;
	}
	
	[pboard declareTypes:[NSArray arrayWithObjects:SOURCE_LIST_DRAG_TYPE, nil] owner:self];
    [pboard setData:[NSData data] forType:SOURCE_LIST_DRAG_TYPE];
	
	return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(CLSourceListItem *)dropTarget proposedChildIndex:(NSInteger)childIndex {
	NSDragOperation result = NSDragOperationNone;
	
	if (dropTarget == nil || dropTarget == sourceListSubscriptions || [dropTarget isKindOfClass:[CLSourceListFolder class]] || [dropTarget isKindOfClass:[CLSourceListFeed class]]) {
		result = NSDragOperationGeneric;
	}
	
	// don't allow dragging from a ancestor to a descendent
	if ([SyndicationAppDelegate isSourceListItem:dropTarget descendentOf:sourceListDragItem]) {
		result = NSDragOperationNone;
	} else {
		
		// various types of drags that we want to redirect
		// the comments below explain which type of drag is being handled
		if ([dropTarget isKindOfClass:[CLSourceListFolder class]] && childIndex != NSOutlineViewDropOnItemIndex) {
			
			// dropping an item between the children of a folder
			[sourceList setDropItem:dropTarget dropChildIndex:NSOutlineViewDropOnItemIndex];
		} else if ([dropTarget isKindOfClass:[CLSourceListFeed class]] && [(CLSourceListFeed *)dropTarget enclosingFolderReference] != nil) {
			
			// dropping an item on top of the child of a folder
			[sourceList setDropItem:[(CLSourceListFeed *)dropTarget enclosingFolderReference] dropChildIndex:NSOutlineViewDropOnItemIndex];
		} else if ([dropTarget isKindOfClass:[CLSourceListFeed class]] && childIndex == NSOutlineViewDropOnItemIndex) {
			
			// dropping an item on to a regular item (not in a folder)
			[sourceList setDropItem:sourceListSubscriptions dropChildIndex:NSOutlineViewDropOnItemIndex];
		} else if (dropTarget == sourceListSubscriptions && childIndex != NSOutlineViewDropOnItemIndex) {
			
			// dropping an item between regular items (not in a folder)
			[sourceList setDropItem:sourceListSubscriptions dropChildIndex:NSOutlineViewDropOnItemIndex];
		} else if (dropTarget == nil) {
			
			// dropping into empty space
			[sourceList setDropItem:sourceListSubscriptions dropChildIndex:NSOutlineViewDropOnItemIndex];
		}
	}
	
	return result;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(CLSourceListItem *)dropTarget childIndex:(NSInteger)childIndex {
	
	if ([info draggingSource] == sourceList) {
		
		CLSourceListFolder *folder = nil;
		
		if (dropTarget != sourceListSubscriptions) {
			folder = (CLSourceListFolder *)dropTarget;
		}
		
		[delegate moveItem:sourceListDragItem toFolder:folder];
		
		return YES;
	}
	
	return NO;
}


# pragma mark CLSourceList delegate methods

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(CLSourceListItem *)item {
	return [item isGroupItem];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(CLSourceListItem *)item {
	return ![item isGroupItem];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(CLSourceListItem *)item {
	return ![item isGroupItem];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(CLSourceListItem *)item {
	return [item isEditable];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(CLSourceListTextFieldCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(CLSourceListItem *)item {
	[cell setBadgeWidth:[CLSourceList sizeOfBadgeForItem:item].width];
	
	if ([item isGroupItem] == NO) {
		[cell setIconWidth:SOURCE_LIST_ICON_WIDTH];
	} else {
		[cell setIconWidth:0];
	}
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	CLSourceListItem *selectedItem = [sourceList itemAtRow:[sourceList selectedRow]];
	
	if (selectedItem != nil) {
		CLTabViewItem *tabViewItem = [tabView selectedTabViewItem];
		
		if ([tabViewItem sourceListItem] != selectedItem) {
			[self openItemInCurrentTab:selectedItem orQuery:nil];
			
			[tabView setNeedsDisplay:YES];
			[[tabViewItem timelineView] setNeedsDisplay:YES];
		}
	}
	
	[self setSourceListSelectedItem:selectedItem];
}


# pragma mark CLTabView actions

- (void)addTabViewItem:(CLTabViewItem *)tabViewItem {
	if (tabViewItem != nil) {
		[tabView addSubview:[tabViewItem spinner]];
		
		[[tabView tabViewItems] addObject:tabViewItem];
		
		[self updateTabRectsAndTrackingRects:YES];
		[self updateAddButtonRectAndTrackingRect:YES];
		[self showOrHideTabBar];
		
		[tabView setNeedsDisplay:YES];
		
		[delegate numberOfTabsDidChange];
	}
}

- (void)addTimelineTabViewItem:(CLTabViewItem *)tabViewItem {
	if (tabViewItem != nil) {
		[self createViewForTimelineTab:tabViewItem];
		[self addTabViewItem:tabViewItem];
	}
}

- (void)addClassicTabViewItem:(CLTabViewItem *)tabViewItem {
	if (tabViewItem != nil) {
		[self createViewForClassicTab:tabViewItem];
		[self addTabViewItem:tabViewItem];
	}
}

- (void)addWebTabViewItem:(CLTabViewItem *)tabViewItem {
	if (tabViewItem != nil) {
		[self createViewForWebTab:tabViewItem];
		[self addTabViewItem:tabViewItem];
	}
}

- (void)createViewForTimelineTab:(CLTabViewItem *)tabViewItem {
	[tabViewItem setTabType:CLTimelineType];
	
	NSRect frame = NSMakeRect(0, 0, [[tabView displayView] frame].size.width, [[tabView displayView] frame].size.height);
	NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:frame];
	[scrollView setHidden:YES];
	[scrollView setBorderType:NSNoBorder];
	[scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[scrollView setHasVerticalScroller:YES];
	[scrollView setHasHorizontalScroller:YES];
	[scrollView setAutohidesScrollers:YES];
	[scrollView setBackgroundColor:[NSColor colorWithCalibratedWhite:0.92 alpha:1.0]];
	
	[[scrollView contentView] setCopiesOnScroll:NO];
	[[scrollView contentView] setPostsBoundsChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timelineClipViewDidScroll:) name:NSViewBoundsDidChangeNotification object:[scrollView contentView]];
	
	NSRect clipViewBounds = [[scrollView contentView] bounds];
	clipViewBounds = NSMakeRect(clipViewBounds.origin.x, clipViewBounds.origin.y, clipViewBounds.size.width, 1);
	CLTimelineView *timelineView = [[CLTimelineView alloc] initWithFrame:clipViewBounds];
	[timelineView setScrollViewReference:scrollView];
	[timelineView setTabViewItemReference:tabViewItem];
	[timelineView setAutoresizingMask:NSViewWidthSizable];
	
	[tabViewItem setLinkedView:scrollView];
	[tabViewItem setTimelineView:timelineView];
	[tabViewItem setTabViewReference:tabView];
	
	[[tabView displayView] addSubview:scrollView];
	[scrollView setDocumentView:timelineView];
	
	[timelineView release];
	[scrollView release];
	
	WebView *informationWebView = [[WebView alloc] initWithFrame:frame];
	[informationWebView setHidden:YES];
	[informationWebView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	
	[timelineView setInformationWebView:informationWebView];
	
	[[tabView displayView] addSubview:informationWebView];
	[informationWebView release];
}

- (void)createViewForClassicTab:(CLTabViewItem *)tabViewItem {
	[tabViewItem setTabType:CLClassicType];
	
	NSRect tabFrame = NSMakeRect(0, 0, [[tabView displayView] frame].size.width, [[tabView displayView] frame].size.height);
	
	CLClassicView *classicView = [[CLClassicView alloc] init];
	[[classicView view] setFrame:tabFrame];
	[[classicView view] setHidden:YES];
	[[classicView webView] setTabViewItemReference:tabViewItem];
	[[classicView webView] setPolicyDelegate:self];
	[[classicView webView] setFrameLoadDelegate:self];
	[[classicView webView] setUIDelegate:self];
	
	NSScrollView *scrollView = (NSScrollView *)[[[classicView tableView] superview] superview];
	
	[[scrollView contentView] setPostsBoundsChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(classicViewTableViewDidScroll:) name:NSViewBoundsDidChangeNotification object:[scrollView contentView]];
	
	[classicView setTabViewItemReference:tabViewItem];
	
	[[classicView tableView] setDataSource:self];
	[[classicView tableView] setDelegate:self];
	
	[[classicView splitView] setDelegate:self];
	
	[[classicView informationWebView] setHidden:YES];
	
	[tabViewItem setLinkedView:[classicView view]];
	[tabViewItem setClassicView:classicView];
	[tabViewItem setTabViewReference:tabView];
	
	[[tabView displayView] addSubview:[classicView view]];
	[classicView release];
	
	WebView *informationWebView = [[WebView alloc] initWithFrame:tabFrame];
	[informationWebView setHidden:YES];
	[informationWebView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	
	[classicView setInformationWebView:informationWebView];
	
	[[tabView displayView] addSubview:informationWebView];
	[informationWebView release];
}

- (void)createViewForWebTab:(CLTabViewItem *)tabViewItem {
	[tabViewItem setTabType:CLWebType];
	
	NSRect tabFrame = NSMakeRect(0, 0, [[tabView displayView] frame].size.width, [[tabView displayView] frame].size.height);
	
	CLWebTab *webTab = [[CLWebTab alloc] init];
	[[webTab view] setFrame:tabFrame];
	[[webTab view] setHidden:YES];
	[[webTab webView] setTabViewItemReference:tabViewItem];
	[[webTab webView] setPolicyDelegate:self];
	[[webTab webView] setFrameLoadDelegate:self];
	[[webTab webView] setUIDelegate:self];
	
	[tabViewItem setLinkedView:[webTab view]];
	[tabViewItem setWebTab:webTab];
	[tabViewItem setTabViewReference:tabView];
	
	[[tabView displayView] addSubview:[webTab view]];
	[webTab release];
}

- (void)removeViewForTimelineTab:(CLTabViewItem *)tabViewItem {
	[[tabViewItem timelineView] removeAllPostsFromTimeline];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:[[[tabViewItem timelineView] scrollViewReference] contentView]];
	[[tabViewItem linkedView] removeFromSuperviewWithoutNeedingDisplay];
	[[[tabViewItem timelineView] informationWebView] removeFromSuperviewWithoutNeedingDisplay];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkIfTimelineNeedsToLoadMoreContent:) object:[tabViewItem timelineView]];
	
	[tabViewItem setTimelineView:nil];
}

- (void)removeViewForClassicTab:(CLTabViewItem *)tabViewItem {
	[[[tabViewItem classicView] webView] stopLoading:self];
	[[[tabViewItem classicView] webView] setTabViewItemReference:nil];
	[[[tabViewItem classicView] webView] setFrameLoadDelegate:nil];
	[[[tabViewItem classicView] webView] setPolicyDelegate:nil];
	[[[tabViewItem classicView] webView] setUIDelegate:nil];
	
	NSScrollView *scrollView = (NSScrollView *)[[[[tabViewItem classicView] tableView] superview] superview];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:[scrollView contentView]];
	
	[[[tabViewItem classicView] tableView] setDataSource:nil];
	[[[tabViewItem classicView] tableView] setDelegate:nil];
	[[tabViewItem classicView] setPosts:[NSMutableArray array]];
	[[tabViewItem classicView] setUnreadItemsDict:[NSMutableDictionary dictionary]];
	[[tabViewItem classicView] setPostsMissingFromBottom:YES];
	
	[[[tabViewItem classicView] splitView] setDelegate:nil];
	
	[[[tabViewItem classicView] tableView] reloadData];
	
	[[tabViewItem linkedView] removeFromSuperviewWithoutNeedingDisplay];
	[tabViewItem setLinkedView:nil];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkIfClassicViewNeedsToLoadMoreContent:) object:[tabViewItem classicView]];
	
	[tabViewItem setClassicView:nil];
}

- (void)removeViewForWebTab:(CLTabViewItem *)tabViewItem {
	[[[tabViewItem webTab] webView] stopLoading:self];
	[[[tabViewItem webTab] webView] setTabViewItemReference:nil];
	[[[tabViewItem webTab] webView] setFrameLoadDelegate:nil];
	[[[tabViewItem webTab] webView] setPolicyDelegate:nil];
	[[[tabViewItem webTab] webView] setUIDelegate:nil];
	
	[[tabViewItem linkedView] removeFromSuperviewWithoutNeedingDisplay];
	[tabViewItem setLinkedView:nil];
	[tabViewItem setWebTab:nil];
}

- (void)openNewTab {
	CLTabViewItem *item = [[CLTabViewItem alloc] init];
	[item setSourceListItem:sourceListNewItems];
	[item setLabel:[sourceListNewItems title]];
	
	if (viewMode == CLTimelineViewMode) {
		[self addTimelineTabViewItem:item];
		[self loadPostsIntoTimeline:[item timelineView] orClassicView:nil];
	} else if (viewMode == CLClassicViewMode) {
		[self addClassicTabViewItem:item];
		[self loadPostsIntoTimeline:nil orClassicView:[item classicView]];
	}
	
	[self selectTabViewItem:item];
	[item release];
}

// used at startup
- (void)openNewEmptyTab {
	CLTabViewItem *item = [[CLTabViewItem alloc] init];
	[item setLabel:@""];
	
	if (viewMode == CLTimelineViewMode) {
		[self addTimelineTabViewItem:item];
	} else if (viewMode == CLClassicViewMode) {
		[self addClassicTabViewItem:item];
	}
	
	[self selectTabViewItem:item];
	[item release];
}

- (void)openNewTabFor:(CLSourceListItem *)subscription selectTab:(BOOL)flag {
	CLTabViewItem *item = [[CLTabViewItem alloc] init];
	[item setSourceListItem:subscription];
	[item setLabel:[subscription extractTitleForDisplay]];
	
	if (viewMode == CLTimelineViewMode) {
		[self addTimelineTabViewItem:item];
		[self loadPostsIntoTimeline:[item timelineView] orClassicView:nil];
	} else if (viewMode == CLClassicViewMode) {
		[self addClassicTabViewItem:item];
		[self loadPostsIntoTimeline:nil orClassicView:[item classicView]];
	}
	
	if (flag) {
		[self selectTabViewItem:item];
	}
	
	[item release];
}

- (CLWebView *)openNewWebTabWith:(NSURLRequest *)request selectTab:(BOOL)flag {
	CLTabViewItem *item = [[CLTabViewItem alloc] init];
	
	if (request != nil) {
		[item setLabel:[[request URL] absoluteString]];
	} else {
		[item setLabel:@"Loading..."];
	}
	
	[self addWebTabViewItem:item];
	[[[[item webTab] webView] mainFrame] loadRequest:request];
	
	if (flag) {
		[self selectTabViewItem:item];
	}
	
	[item release];
	
	return [[item webTab] webView];
}

- (void)openInTab:(CLTabViewItem *)tabViewItem item:(CLSourceListItem *)item orQuery:(NSString *)queryString {
	
	if ([tabViewItem tabType] == CLWebType) {
		[self removeViewForWebTab:tabViewItem];
	} else if ([tabViewItem tabType] == CLTimelineType) {
		[self removeViewForTimelineTab:tabViewItem];
	} else if ([tabViewItem tabType] == CLClassicType) {
		[self removeViewForClassicTab:tabViewItem];
	}
	
	[tabViewItem setSourceListItem:item];
	[tabViewItem setSearchQuery:queryString];
	
	if (queryString != nil) {
		[tabViewItem setLabel:queryString];
	} else {
		[tabViewItem setLabel:[item extractTitleForDisplay]];
	}
	
	if (viewMode == CLTimelineViewMode) {
		[self createViewForTimelineTab:tabViewItem];
		[self loadPostsIntoTimeline:[tabViewItem timelineView] orClassicView:nil];
	} else if (viewMode == CLClassicViewMode) {
		[self createViewForClassicTab:tabViewItem];
		[self loadPostsIntoTimeline:nil orClassicView:[tabViewItem classicView]];
	}
	
	[self updateViewVisibilityForTab:tabViewItem];
	
	[tabViewItem setIsLoading:NO];
	[tabView setNeedsDisplay:YES];
	
	[self updateWindowTitle];
	[self performSelector:@selector(updateFirstResponder) withObject:nil afterDelay:0.1]; // don't ask
	[self updateViewSwitchEnabled];
}

- (void)openItemInCurrentTab:(CLSourceListItem *)item orQuery:(NSString *)queryString {
	CLTabViewItem *tabViewItem = [tabView selectedTabViewItem];
	
	// if the content is switching but the view type is the same, just load the new content
	// otherwise, we need to tear down and create the new view first
	if (([tabViewItem tabType] == CLTimelineType && viewMode == CLTimelineViewMode) || ([tabViewItem tabType] == CLClassicType && viewMode == CLClassicViewMode)) {
		[tabViewItem setSourceListItem:item];
		[tabViewItem setSearchQuery:queryString];
		
		if (queryString != nil) {
			[tabViewItem setLabel:queryString];
		} else {
			[tabViewItem setLabel:[item extractTitleForDisplay]];
		}
		
		[tabView setNeedsDisplay:YES];
		[self updateWindowTitle];
		
		[self reloadContentForTab:tabViewItem];
	} else {
		[self openInTab:tabViewItem item:item orQuery:queryString];
	}
}

- (void)reloadContentForTab:(CLTabViewItem *)tabViewItem {
	
	if ([tabViewItem tabType] == CLTimelineType) {
		
		[[tabViewItem timelineView] removeAllPostsFromTimeline];
		[tabViewItem setLinkedView:[[tabViewItem timelineView] scrollViewReference]];
		
		[self loadPostsIntoTimeline:[tabViewItem timelineView] orClassicView:nil];
		
	} else if ([tabViewItem tabType] == CLClassicType) {
		
		[[tabViewItem classicView] setPosts:[NSMutableArray array]];
		[[tabViewItem classicView] setUnreadItemsDict:[NSMutableDictionary dictionary]];
		[[tabViewItem classicView] setPostsMissingFromBottom:YES];
		[[tabViewItem classicView] setDisplayedPost:nil];
		[[tabViewItem classicView] setShouldIgnoreSelectionChange:NO];
		[tabViewItem setLinkedView:[[tabViewItem classicView] view]];
		[[[tabViewItem classicView] tableView] reloadData];
		
		NSClipView *clipView = (NSClipView *)[[[tabViewItem classicView] tableView] superview];
		NSScrollView *scrollView = (NSScrollView *)[clipView superview];
		[scrollView clScrollToTop];
		
		[[[[tabViewItem classicView] webView] mainFrame] loadHTMLString:@"" baseURL:nil];
		
		[self loadPostsIntoTimeline:nil orClassicView:[tabViewItem classicView]];
	}
	
	[self performSelector:@selector(updateFirstResponder) withObject:nil afterDelay:0.1]; // don't ask
}

- (void)updateViewVisibilityForTab:(CLTabViewItem *)tabViewItem {
	CLSourceListItem *sourceListItem = [tabViewItem sourceListItem];
	NSString *searchQuery = [tabViewItem searchQuery];
	NSString *message = @"";
	
	if (sourceListItem == sourceListNewItems) {
		message = @"No new items";
	} else if (sourceListItem == sourceListStarredItems) {
		message = @"No starred items";
	} else if (sourceListItem != nil) {
		if ([sourceListItem title] != nil && [[sourceListItem title] length] > 0) {
			message = [NSString stringWithFormat:@"No items found for %@", [sourceListItem title]];
		} else {
			message = @"No items found";
		}
	} else if (searchQuery != nil) {
		message = [NSString stringWithFormat:@"No results found for \"%@\"", searchQuery];
	}
	
	NSString *htmlString = [NSString stringWithFormat:NO_POSTS_HTML_STRING, message];
	
	if ([tabViewItem tabType] == CLTimelineType) {
		CLTimelineView *timelineView = [tabViewItem timelineView];
		
		if ([tabViewItem isSelected] == NO) {
			[[timelineView scrollViewReference] setHidden:YES];
			[[timelineView informationWebView] setHidden:YES];
		}
		
		if ([[timelineView timelineViewItems] count] == 0) {
			
			if ([tabViewItem isSelected]) {
				[[timelineView scrollViewReference] setHidden:YES];
				[[timelineView informationWebView] setHidden:NO];
			}
			
			[[[timelineView informationWebView] mainFrame] loadHTMLString:htmlString baseURL:nil];
			
			[tabViewItem setLinkedView:[timelineView informationWebView]];
			
		} else {
			
			if ([tabViewItem isSelected]) {
				[[timelineView scrollViewReference] setHidden:NO];
				[[timelineView informationWebView] setHidden:YES];
			}
			
			// if scroll is not at the very top and selectedItem is nil, select item at the top
			NSScrollView *scrollView = [timelineView scrollViewReference];
			NSRect visibleRect = [scrollView documentVisibleRect];
			
			if (visibleRect.origin.y > 0 && [timelineView selectedItem] == nil) {
				[self selectItemAtTopOfTimelineView:timelineView];
			}
			
			[tabViewItem setLinkedView:[timelineView scrollViewReference]];
		}
		
	} else if ([tabViewItem tabType] == CLClassicType) {
		CLClassicView *classicView = [tabViewItem classicView];
		
		if ([tabViewItem isSelected] == NO) {
			[[classicView view] setHidden:YES];
			[[classicView informationWebView] setHidden:YES];
		}
		
		if ([[classicView posts] count] == 0) {
			
			if ([tabViewItem isSelected]) {
				[[classicView view] setHidden:YES];
				[[classicView informationWebView] setHidden:NO];
			}
			
			[[[classicView informationWebView] mainFrame] loadHTMLString:htmlString baseURL:nil];
			
			[tabViewItem setLinkedView:[classicView informationWebView]];
		} else {
			
			if ([tabViewItem isSelected]) {
				[[classicView view] setHidden:NO];
				[[classicView informationWebView] setHidden:YES];
			}
			
			[tabViewItem setLinkedView:[classicView view]];
		}
	}
	
	if ([tabViewItem isSelected]) {
		[[tabViewItem linkedView] setHidden:NO];
		[[tabViewItem linkedView] setNeedsDisplay:YES];
	}
}

- (void)closeTab {
	[self removeTabViewItem:[tabView selectedTabViewItem]];
}

- (void)closeAllTabsForFeed:(CLSourceListFeed *)feed {
	if (feed != nil) {
		NSMutableArray *itemsToRemove = [NSMutableArray array];
		
		for (CLTabViewItem *tabViewItem in [tabView tabViewItems]) {
			if ([tabViewItem sourceListItem] != nil && [[tabViewItem sourceListItem] isKindOfClass:[CLSourceListItem class]]) {
				if ([tabViewItem sourceListItem] == feed) {
					[itemsToRemove addObject:tabViewItem];
				}
			}
		}
		
		for (CLTabViewItem *tabViewItem in itemsToRemove) {
			[self removeTabViewItem:tabViewItem];
		}
	}
}

- (void)closeAllTabsForFolderOrDescendent:(CLSourceListFolder *)folder {
	if (folder != nil) {
		NSMutableArray *itemsToRemove = [NSMutableArray array];
		
		for (CLTabViewItem *tabViewItem in [tabView tabViewItems]) {
			if ([tabViewItem sourceListItem] != nil && [[tabViewItem sourceListItem] isKindOfClass:[CLSourceListItem class]]) {
				if ([tabViewItem sourceListItem] == folder || [SyndicationAppDelegate isSourceListItem:[tabViewItem sourceListItem] descendentOf:folder]) {
					[itemsToRemove addObject:tabViewItem];
				}
			}
		}
		
		for (CLTabViewItem *tabViewItem in itemsToRemove) {
			[self removeTabViewItem:tabViewItem];
		}
	}
}

- (void)removeTabViewItem:(CLTabViewItem *)tabViewItem {
	if (tabViewItem != nil) {
		if (tabViewItem == [tabView selectedTabViewItem]) {
			NSUInteger indexOfTabViewItem = [self indexOfTabViewItem:tabViewItem];
			
			if (indexOfTabViewItem == ([self numberOfTabViewItems] - 1)) {
				[self selectTabViewItemAtIndex:(indexOfTabViewItem - 1)];
			} else {
				[self selectTabViewItemAtIndex:(indexOfTabViewItem + 1)];
			}
		}
		
		if ([tabViewItem tabType] == CLWebType) {
			[self removeViewForWebTab:tabViewItem];
		} else if ([tabViewItem tabType] == CLTimelineType) {
			[self removeViewForTimelineTab:tabViewItem];
		} else if ([tabViewItem tabType] == CLClassicType) {
			[self removeViewForClassicTab:tabViewItem];
		}
		
		[[tabView tabViewItems] removeObject:tabViewItem];
		
		[self updateTabRectsAndTrackingRects:YES];
		[self updateAddButtonRectAndTrackingRect:YES];
		[self showOrHideTabBar];
		
		[tabView setNeedsDisplay:YES];
		
		[delegate numberOfTabsDidChange];
	}
	
	if ([self numberOfTabViewItems] == 0) {
		[self openNewTab];
	}
}

- (NSUInteger)numberOfTabViewItems {
	return [[tabView tabViewItems] count];
}

- (NSUInteger)indexOfTabViewItem:(CLTabViewItem *)tabViewItem {
	
	if (tabViewItem == nil) {
		return NSNotFound;
	}
	
	return [[tabView tabViewItems] indexOfObject:tabViewItem];
}

- (void)selectTabViewItem:(CLTabViewItem *)tabViewItem {
	
	if ([tabView selectedTabViewItem] != tabViewItem) {
		if ([tabView selectedTabViewItem] != nil) {
			[[[tabView selectedTabViewItem] linkedView] setHidden:YES];
			[[[tabView selectedTabViewItem] linkedView] setNeedsDisplay:NO];
		}
		
		if ([tabViewItem tabType] == CLTimelineType) {
			
			// width may have changed since we last displayed this timeline, so recalculate all heights
			CLTimelineView *timelineView = [tabViewItem timelineView];
			BOOL subviewRectsNeedUpdating = NO;
			
			for (CLTimelineViewItem *timelineViewItem in [timelineView timelineViewItems]) {
				if ([timelineViewItem updateHeight]) {
					subviewRectsNeedUpdating = YES;
				}
			}
			
			if (subviewRectsNeedUpdating) {
				[timelineView updateSubviewRects];
				[timelineView setNeedsDisplay:YES];
			}
		}
		
		[[tabViewItem linkedView] setHidden:NO];
		[[tabViewItem linkedView] setNeedsDisplay:YES];
		
		// remember value of search box
		[[tabView selectedTabViewItem] setSearchFieldValue:[searchField stringValue]];
		
		if ([tabViewItem searchFieldValue] == nil) {
			[searchField setStringValue:@""];
		} else {
			[searchField setStringValue:[tabViewItem searchFieldValue]];
		}
		
		[[tabView selectedTabViewItem] setIsSelected:NO];
		[tabView setSelectedTabViewItem:tabViewItem];
		[tabViewItem setIsSelected:YES];
		
		[tabView setNeedsDisplay:YES];
		
		[self updateWindowTitle];
		[self updateFirstResponder];
		[self updateViewSwitchEnabled];
		
		[delegate tabSelectionDidChange];
	}
}

- (void)selectTabViewItemAtIndex:(NSUInteger)tabIndex {
	if ([self numberOfTabViewItems] > 0) {
		
		if (tabIndex >= [self numberOfTabViewItems]) {
			tabIndex = ([self numberOfTabViewItems] - 1);
		}
		
		CLTabViewItem *toSelect = [[tabView tabViewItems] objectAtIndex:tabIndex];
		[self selectTabViewItem:toSelect];
	}
}

- (void)selectFirstTabViewItem {
	[self selectTabViewItemAtIndex:0];
}

- (void)selectLastTabViewItem {
	[self selectTabViewItemAtIndex:([self numberOfTabViewItems] - 1)];
}

- (void)selectNextTabViewItem {
	if ([tabView selectedTabViewItem] != nil) {
		NSInteger indexOfSelectedItem = [self indexOfTabViewItem:[tabView selectedTabViewItem]];
		NSUInteger nextIndex = indexOfSelectedItem + 1;
		
		if (nextIndex >= [self numberOfTabViewItems]) {
			nextIndex = 0;
		}
		
		[self selectTabViewItemAtIndex:nextIndex];
	}
}

- (void)selectPreviousTabViewItem {
	if ([tabView selectedTabViewItem] != nil) {
		NSInteger indexOfSelectedItem = [self indexOfTabViewItem:[tabView selectedTabViewItem]];
		NSInteger prevIndex = indexOfSelectedItem - 1;
		
		if (prevIndex < 0) {
			prevIndex = ([self numberOfTabViewItems] - 1);
		}
		
		[self selectTabViewItemAtIndex:prevIndex];
	}
}

- (void)showOrHideTabBar {
	if ([self numberOfTabViewItems] > 1) {
		if ([tabView frame].size.height == 0) {
			[tabView setFrameSize:NSMakeSize([tabView frame].size.width, TAB_BAR_HEIGHT)];
			[[tabView displayView] setFrameSize:NSMakeSize([[tabView displayView] frame].size.width, [[tabView displayView] frame].size.height - TAB_BAR_HEIGHT)];
		}
	} else {
		if ([tabView frame].size.height == TAB_BAR_HEIGHT) {
			[tabView setFrameSize:NSMakeSize([tabView frame].size.width, 0)];
			[[tabView displayView] setFrameSize:NSMakeSize([[tabView displayView] frame].size.width, [[tabView displayView] frame].size.height + TAB_BAR_HEIGHT)];
		}
	}
}


#pragma mark timeline/classic view stuff

- (void)setSelectedItem:(CLTimelineViewItem *)item forTimelineView:(CLTimelineView *)timelineView {
	
	CLTimelineViewItem *selectedItem = [timelineView selectedItem];
	
	if (item != selectedItem) {
		
		if (selectedItem != nil) {
			[selectedItem setIsSelected:NO];
			[selectedItem updateClassNames];
		}
		
		if (item != nil) {
			[item setIsSelected:YES];
			[item updateClassNames];
		}
		
		[timelineView setSelectedItem:item];
		
		[delegate timelineSelectionDidChange];
		
		if (item != nil) {
			if ([item isRead] == NO) {
				[delegate markPostWithDbIdAsRead:[item postDbId]];
			}
		}
	}
}

- (void)scrollTimelineViewItem:(CLTimelineViewItem *)item toTopOfTimelineView:(CLTimelineView *)timelineView {
	[timelineView setShouldIgnoreScrollEvent:YES];
	
	NSScrollView *scrollView = [timelineView scrollViewReference];
	[scrollView clScrollInstantlyTo:NSMakePoint(0, [[item view] frame].origin.y - TIMELINE_FIRST_ITEM_MARGIN_TOP)];
}

- (void)selectNextItemForTimelineView:(CLTimelineView *)timelineView {
	if ([[timelineView timelineViewItems] count] == 0) {
		return;
	}
	
	if ([timelineView selectedItem] == nil) {
		CLTimelineViewItem *item = [[timelineView timelineViewItems] objectAtIndex:0];
		[self userSelectItem:item forTimelineView:timelineView];
		return;
	}
	
	NSUInteger indexOfSelectedItem = [[timelineView timelineViewItems] indexOfObject:[timelineView selectedItem]];
	
	// this should never happen, but check for it anyway
	if (indexOfSelectedItem == NSNotFound) {
		return;
	}
	
	if (indexOfSelectedItem < ([[timelineView timelineViewItems] count] - 1)) {
		CLTimelineViewItem *item = [[timelineView timelineViewItems] objectAtIndex:(indexOfSelectedItem + 1)];
		[self userSelectItem:item forTimelineView:timelineView];
	}
}

- (void)selectPreviousItemForTimelineView:(CLTimelineView *)timelineView {
	if ([[timelineView timelineViewItems] count] == 0) {
		return;
	}
	
	if ([timelineView selectedItem] == nil) {
		CLTimelineViewItem *item = [[timelineView timelineViewItems] objectAtIndex:0];
		[self userSelectItem:item forTimelineView:timelineView];
		return;
	}
	
	NSUInteger indexOfSelectedItem = [[timelineView timelineViewItems] indexOfObject:[timelineView selectedItem]];
	
	// this should never happen, but check for it anyway
	if (indexOfSelectedItem == NSNotFound) {
		return;
	}
	
	if (indexOfSelectedItem > 0) {
		CLTimelineViewItem *item = [[timelineView timelineViewItems] objectAtIndex:(indexOfSelectedItem - 1)];
		[self userSelectItem:item forTimelineView:timelineView];
	} else if (indexOfSelectedItem == 0) {
		CLTimelineViewItem *item = [[timelineView timelineViewItems] objectAtIndex:0];
		[self scrollTimelineViewItem:item toTopOfTimelineView:timelineView];
	}
}

- (void)userSelectItem:(CLTimelineViewItem *)item forTimelineView:(CLTimelineView *)timelineView {
	[self setSelectedItem:item forTimelineView:timelineView];
	[self scrollTimelineViewItem:item toTopOfTimelineView:timelineView];
	[self performSelector:@selector(checkIfTimelineNeedsToUnloadContent:) withObject:timelineView afterDelay:0.0];
	[self performSelector:@selector(checkIfTimelineNeedsToLoadMoreContent:) withObject:timelineView afterDelay:0.0];
}

- (void)selectItemAtTopOfTimelineView:(CLTimelineView *)timelineView {
	NSScrollView *scrollView = [timelineView scrollViewReference];
	NSClipView *clipView = [scrollView contentView];
	CLTimelineViewItem *selectedTimelineViewItem = [timelineView selectedItem];
	CLTabViewItem *tabViewItem = [timelineView tabViewItemReference];
	
	// check to make sure this isn't an empty tab
	if ([tabViewItem sourceListItem] != nil || [tabViewItem searchQuery] != nil) {
		CGFloat clipViewYOrigin = [clipView documentVisibleRect].origin.y;
		CGFloat itemYOrigin = 0.0;
		CGFloat itemHeight = 0.0;
		
		// only select top item if the timeline is scrolled or an item is already selected
		if (clipViewYOrigin > 0 || selectedTimelineViewItem != nil) {
			for (CLTimelineViewItem *item in [timelineView timelineViewItems]) {
				itemYOrigin = [[item view] frame].origin.y;
				itemHeight = [[item view] frame].size.height;
				
				if (clipViewYOrigin >= (itemYOrigin - TIMELINE_SCROLL_BUFFER) && clipViewYOrigin < (itemYOrigin + itemHeight - TIMELINE_SCROLL_BUFFER - 3)) {
					
					if (item != selectedTimelineViewItem) {
						[self setSelectedItem:item forTimelineView:timelineView];
						[self checkIfTimelineNeedsToUnloadContent:timelineView];
						[self checkIfTimelineNeedsToLoadMoreContent:timelineView];
					}
					
					break;
				}
			}
		}
	}
}

- (void)timelineClipViewDidScroll:(NSNotification *)notification {
	NSClipView *clipView = [notification object];
	NSScrollView *scrollView = (NSScrollView *)[clipView superview];
	CLTimelineView *timelineView = [scrollView documentView];
	
	if ([timelineView shouldIgnoreScrollEvent] == NO || [timelineView selectedItem] == nil) {
		[self selectItemAtTopOfTimelineView:timelineView];
	}
	
	[timelineView setShouldIgnoreScrollEvent:NO];
}

- (void)checkIfTimelineNeedsToLoadMoreContent:(CLTimelineView *)timelineView {
	NSClipView *clipView = (NSClipView *)[timelineView superview];
	CLTimelineViewItem *selectedTimelineViewItem = [timelineView selectedItem];
	NSInteger postsPerScreen = [self numberOfTimelineViewItemsPerScreenOfClipView:clipView];
	NSInteger threshold = postsPerScreen + 1;
	
	if ([timelineView postsMissingFromTopCount] > 0) {
		
		NSInteger numberOfPostsBeforeSelectedItem = 0;
		
		if (selectedTimelineViewItem != nil) {
			NSInteger indexOfSelectedItem = [[timelineView timelineViewItems] indexOfObject:selectedTimelineViewItem];
			numberOfPostsBeforeSelectedItem = indexOfSelectedItem;
		}
		
		if (numberOfPostsBeforeSelectedItem < threshold) {
			NSRange range;
			
			if ([timelineView postsMissingFromTopCount] < TIMELINE_POSTS_PER_QUERY) {
				range = NSMakeRange(0, [timelineView postsMissingFromTopCount]);
			} else {
				range = NSMakeRange(0, TIMELINE_POSTS_PER_QUERY);
			}
			
			[self loadPostsIntoTimeline:timelineView orClassicView:nil fromRange:range atBottom:NO];
		}
	}
	
	NSInteger numberOfPosts = [[timelineView timelineViewItems] count];
	
	if ([timelineView postsMissingFromBottom]) {
		
		NSInteger numberOfPostsAfterSelectedItem = numberOfPosts;
		
		if (selectedTimelineViewItem != nil) {
			NSInteger indexOfSelectedItem = [[timelineView timelineViewItems] indexOfObject:selectedTimelineViewItem];
			numberOfPostsAfterSelectedItem = numberOfPosts - indexOfSelectedItem - 1;
		}
		
		if (numberOfPostsAfterSelectedItem < threshold) {
			[self loadPostsIntoTimeline:timelineView orClassicView:nil];
		}
	}
}

- (void)checkIfTimelineNeedsToUnloadContent:(CLTimelineView *)timelineView {
	NSClipView *clipView = (NSClipView *)[timelineView superview];
	CLTimelineViewItem *selectedTimelineViewItem = [timelineView selectedItem];
	NSInteger postsPerScreen = [self numberOfTimelineViewItemsPerScreenOfClipView:clipView];
	NSInteger threshold = (postsPerScreen * TIMELINE_UNLOAD_MULTIPLIER);
	
	if (selectedTimelineViewItem != nil) {
		NSInteger numberOfPostsBeforeSelectedItem = [[timelineView timelineViewItems] indexOfObject:selectedTimelineViewItem];
		
		if (numberOfPostsBeforeSelectedItem > threshold) {
			NSInteger numberOfPostsToRemove = numberOfPostsBeforeSelectedItem - threshold;
			
			if (numberOfPostsToRemove > 0) {
				[timelineView removePostsInRange:NSMakeRange(0, numberOfPostsToRemove) preserveScrollPosition:YES updateMetadata:YES];
				[timelineView updateSubviewRects];
				[timelineView setNeedsDisplay:YES];
			}
		}
	}
	
	NSInteger numberOfPosts = [[timelineView timelineViewItems] count];
	NSInteger numberOfPostsAfterSelectedItem = numberOfPosts;
	
	if (selectedTimelineViewItem != nil) {
		NSInteger indexOfSelectedItem = [[timelineView timelineViewItems] indexOfObject:selectedTimelineViewItem];
		numberOfPostsAfterSelectedItem = numberOfPosts - indexOfSelectedItem - 1;
	}
	
	if (numberOfPostsAfterSelectedItem > threshold) {
		NSInteger numberOfPostsToRemove = numberOfPostsAfterSelectedItem - threshold;
		
		if (numberOfPostsToRemove > 0) {
			NSRange range = NSMakeRange((numberOfPosts - numberOfPostsToRemove), numberOfPostsToRemove);
			[timelineView removePostsInRange:range preserveScrollPosition:NO updateMetadata:YES];
			[timelineView updateSubviewRects];
			[timelineView setNeedsDisplay:YES];
		}
	}
}

- (void)classicViewTableViewDidScroll:(NSNotification *)notification {
	NSClipView *clipView = [notification object];
	NSScrollView *scrollView = (NSScrollView *)[clipView superview];
	CLTableView *tableView = [scrollView documentView];
	CLClassicView *classicView = [tableView classicViewReference];
	
	[self checkIfClassicViewNeedsToUnloadContent:classicView];
	[self checkIfClassicViewNeedsToLoadMoreContent:classicView];
}

- (void)checkIfClassicViewNeedsToLoadMoreContent:(CLClassicView *)classicView {
	NSClipView *clipView = (NSClipView *)[[classicView tableView] superview];
	NSScrollView *scrollView = (NSScrollView *)[clipView superview];
	
	if ([classicView postsMissingFromBottom]) {
		NSRect visibleRect = [scrollView documentVisibleRect];
		NSInteger clipHeight = visibleRect.size.height;
		NSInteger totalContentHeight = [[scrollView documentView] frame].size.height;
		NSInteger remainingContent = totalContentHeight - ((NSInteger)visibleRect.origin.y + clipHeight);
		
		if (remainingContent < clipHeight) {
			[self loadPostsIntoTimeline:nil orClassicView:classicView];
		}
	}
}

- (void)checkIfClassicViewNeedsToUnloadContent:(CLClassicView *)classicView {
	NSClipView *clipView = (NSClipView *)[[classicView tableView] superview];
	NSScrollView *scrollView = (NSScrollView *)[clipView superview];
	
	NSRect visibleRect = [scrollView documentVisibleRect];
	NSInteger clipHeight = visibleRect.size.height;
	NSInteger rowHeight = [[classicView tableView] rowHeight];
	NSInteger totalContentHeight = [[scrollView documentView] frame].size.height;
	NSInteger remainingContent = totalContentHeight - ((NSInteger)visibleRect.origin.y + clipHeight);
	NSInteger excessContent = remainingContent - (clipHeight * 15) - (rowHeight * CLASSIC_VIEW_POSTS_PER_QUERY);
	
	if (excessContent > 0) {
		NSInteger numberOfRowsToRemove = excessContent / rowHeight;
		
		if (numberOfRowsToRemove > 0) {
			NSRange range = NSMakeRange(([[classicView posts] count] - numberOfRowsToRemove), numberOfRowsToRemove);
			[classicView removePostsInRange:range preserveScrollPosition:NO updateMetadata:YES ignoreSelection:YES];
		}
	}
}

- (NSInteger)numberOfTimelineViewItemsPerScreenOfClipView:(NSClipView *)clipView {
	NSInteger numberOfItems = 0;
	NSInteger minItems = 10;
	NSRect visibleRect = [clipView documentVisibleRect];
	NSInteger clipHeight = visibleRect.size.height;
	
	numberOfItems = floor(clipHeight / TIMELINE_ITEM_DEFAULT_HEIGHT) + 1;
	
	if (numberOfItems < minItems) {
		numberOfItems = minItems;
	}
	
	return numberOfItems;
}


# pragma mark window notifications

- (void)windowDidResize:(NSNotification *)notification {
	if ([[tabView selectedTabViewItem] tabType] == CLTimelineType) {
		CLTimelineView *timelineView = [[tabView selectedTabViewItem] timelineView];
		
		BOOL subviewRectsNeedUpdating = NO;
		
		for (CLTimelineViewItem *timelineViewItem in [timelineView timelineViewItems]) {
			if ([timelineViewItem updateHeight]) {
				subviewRectsNeedUpdating = YES;
			}
		}
		
		if (subviewRectsNeedUpdating) {
			[timelineView updateSubviewRects];
			[timelineView setNeedsDisplay:YES];
		}
	}
}

- (void)windowDidEndLiveResize:(NSNotification *)notification {
	[self updateTabRectsAndTrackingRects:YES];
	[self updateAddButtonRectAndTrackingRect:YES];
	[tabView setNeedsDisplay:YES];
	
	if ([[tabView selectedTabViewItem] tabType] == CLTimelineType) {
		CLTimelineView *timelineView = [[tabView selectedTabViewItem] timelineView];
		
		for (CLTimelineViewItem *timelineViewItem in [timelineView timelineViewItems]) {
			[timelineViewItem updateHeight];
			
			// refresh again after timer fires to fix drawing errors
			if ([timelineViewItem heightUpdateTimer] != nil) {
				if ([[timelineViewItem heightUpdateTimer] isValid]) {
					[[timelineViewItem heightUpdateTimer] invalidate];
					[timelineViewItem setHeightUpdateTimer:nil];
				}
			}
			
			CLTimer *refreshTimer = [CLTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(webViewHeightTimerFired:) userInfo:timelineViewItem repeats:YES];
			[timelineViewItem setHeightUpdateTimer:refreshTimer];
			[timelineViewItem setHeightUpdateCount:0];
		}
		
		[timelineView updateSubviewRects];
		[timelineView setNeedsDisplay:YES];
	}
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
	[tabView setNeedsDisplay:YES];
	[sourceList setIsWindowFocused:YES];
}

- (void)windowDidResignMain:(NSNotification *)notification {
	[sourceList setIsWindowFocused:NO];
}


# pragma mark WebView stuff

- (void)webView:(CLWebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id <WebPolicyDecisionListener>)listener {
	
	CLTabViewItem *tabViewItem = [sender tabViewItemReference];
	CLTabViewItemType tabType = [tabViewItem tabType];
	
	NSInteger navigationType = [[actionInformation valueForKey:@"WebActionNavigationTypeKey"] integerValue];
	NSInteger mouseButton = [[actionInformation valueForKey:@"WebActionButtonKey"] integerValue];
	NSString *urlString = [[request URL] absoluteString];
	NSString *urlScheme = [[request URL] scheme];
	
	if (urlString == nil) {
		[listener ignore];
		return;
	}
	
	if ([urlString isEqual:@"about:blank"]) {
		[listener use];
		return;
	}
	
	if (tabType == CLTimelineType || tabType == CLClassicType) {
		
		if ([urlString length] > 51 && [urlScheme isEqual:@"applewebdata"]) {
			urlString = [urlString substringFromIndex:51];
			request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:[request cachePolicy] timeoutInterval:[request timeoutInterval]];
		}
		
		// check to see if this is a link to an anchor within the post itself (like a footnote, for example)
		if ([[urlString substringToIndex:1] isEqual:@"#"]) {
			
			if (tabType == CLTimelineType) {
				CLTimelineViewItemView *timelineViewItemView = (CLTimelineViewItemView *)[sender superview];
				CLTimelineViewItem *timelineViewItem = [timelineViewItemView timelineViewItemReference];
				CLTimelineView *timelineView = [timelineViewItem timelineViewReference];
				
				[self timelineView:timelineView timelineViewItem:timelineViewItem scrollToAnchor:[urlString substringFromIndex:1]];
			} else if (tabType == CLClassicType) {
				CLClassicView *classicView = [tabViewItem classicView];
				[self classicView:classicView scrollToAnchor:[urlString substringFromIndex:1]];
			}
			
			[listener ignore];
			return;
		}
	}
	
	// if this is a weird link, let the OS handle it
	if (![urlScheme isEqual:@"http"] && ![urlScheme isEqual:@"https"] && ![urlScheme isEqual:@"file"] && ![urlString isEqual:@"about:blank"]) {
		BOOL response = [[NSWorkspace sharedWorkspace] openURL:[request URL]];
		
		if (response == NO) {
			if (navigationType == WebNavigationTypeLinkClicked) {
				[CLErrorHelper createAndDisplayError:@"Unable to load URL."];
			}
		}
		
		[listener ignore];
		return;
	}
	
	if (navigationType == WebNavigationTypeLinkClicked) {
		
		// 1 == middle button
		// AFAIK, there is no apple-defined constants for these
		if (mouseButton == 1) {
			[self openNewWebTabWith:request selectTab:NO];
			[listener ignore];
			return;
		} else {
			BOOL commandKeyIsDown = (([NSEvent modifierFlags] & NSCommandKeyMask) > 0);
			
			if (commandKeyIsDown) {
				[self openNewWebTabWith:request selectTab:NO];
				[listener ignore];
				return;
			} else if (tabType == CLTimelineType || tabType == CLClassicType) {
				[self openNewWebTabWith:request selectTab:YES];
				[listener ignore];
				return;
			}
		}
	}
	
	if (tabType == CLWebType) {
		if (frame == [sender mainFrame]) {
			CLWebTab *webTab = [tabViewItem webTab];
			[webTab setUrlString:urlString];
			[webTab setTitleReceived:NO];
			[[[webTab toolbarView] textField] setStringValue:urlString];
		}
	}
	
	[listener use];
}

- (void)webView:(CLWebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame {
	
	CLTabViewItem *tabViewItem = [sender tabViewItemReference];
	CLTabViewItemType tabType = [tabViewItem tabType];
	
	if (frame == [sender mainFrame]) {
		if (tabType == CLWebType) {
			CLWebTab *webTab = [tabViewItem webTab];
			[tabViewItem setLabel:title];
			[tabView setNeedsDisplay:YES];
			
			[webTab setTitleReceived:YES];
			
			if ([tabViewItem isSelected]) {
				NSWindow *window = [self window];
				[window setTitle:title];
			}
		}
	}
}

- (void)webView:(CLWebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
	
	CLTabViewItem *tabViewItem = [sender tabViewItemReference];
	CLTabViewItemType tabType = [tabViewItem tabType];
	
	if (frame == [sender mainFrame]) {
		if (tabType == CLWebType) {
			[tabViewItem setIsLoading:YES];
			[tabView setNeedsDisplay:YES];
		}
	}
}

- (void)webView:(CLWebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	
	CLTabViewItem *tabViewItem = [sender tabViewItemReference];
	CLTabViewItemType tabType = [tabViewItem tabType];
	
	if (frame == [sender mainFrame]) {
		
		// 204 is "Plug-in handled load", couldn't find constant for it
		if ([error code] == 204) {
			if (tabType == CLWebType) {
				[tabViewItem setIsLoading:NO];
				
				NSString *fileUrlString = [sender mainFrameURL];
				
				if (fileUrlString != nil) {
					[tabViewItem setLabel:fileUrlString];
				}
				
				[tabView setNeedsDisplay:YES];
				
				return;
			}
		}
		
		if ([error code] != NSURLErrorCancelled) {
			if (tabType == CLWebType) {
				[tabViewItem setIsLoading:NO];
				[tabView setNeedsDisplay:YES];
				
				[NSApp presentError:error];
			}
		}
	}
}

- (void)webView:(CLWebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	
	CLTabViewItem *tabViewItem = [sender tabViewItemReference];
	CLTabViewItemType tabType = [tabViewItem tabType];
	
	if (frame == [sender mainFrame]) {
		if ([error code] != NSURLErrorCancelled) {
			if (tabType == CLWebType) {
				[tabViewItem setIsLoading:NO];
				[tabView setNeedsDisplay:YES];
				
				// let the default web browser handle file downloads
				if ([error code] == 102) {
					CLWebTab *webTab = [tabViewItem webTab];
					NSString *urlString = [webTab urlString];
					NSURL *url = [NSURL URLWithString:urlString];
					
					BOOL response = [[NSWorkspace sharedWorkspace] openURL:url];
					
					if (response == NO) {
						[CLErrorHelper createAndDisplayError:@"Unable to load URL."];
					}
					
					return;
				}
				
				// change the text for invalid ssl certificate warnings
				if ([error code] == NSURLErrorServerCertificateUntrusted) {
					NSDictionary *userInfo = [error userInfo];
					NSMutableDictionary *newUserInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
					[newUserInfo removeObjectForKey:NSLocalizedRecoverySuggestionErrorKey];
					userInfo = [NSMutableDictionary dictionaryWithDictionary:newUserInfo];
					
					error = [NSError errorWithDomain:[error domain] code:[error code] userInfo:userInfo];
				}
				
				[NSApp presentError:error];
			}
		}
	}
}

- (void)webView:(CLWebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	
	CLTabViewItem *tabViewItem = [sender tabViewItemReference];
	
	if (tabViewItem != nil) {
		CLTabViewItemType tabType = [tabViewItem tabType];
		
		if (frame == [sender mainFrame]) {
			if (tabType == CLWebType) {
				CLWebTab *webTab = [tabViewItem webTab];
				[tabViewItem setIsLoading:NO];
				
				if ([webTab titleReceived] == NO) {
					[tabViewItem setLabel:[webTab urlString]];
				}
				
				[tabView setNeedsDisplay:YES];
				
				[webTab updateBackForwardEnabled];
				
				[delegate webTabDidFinishLoad];
				
			} else if (tabType == CLTimelineType) {
				CLTimelineViewItemView *timelineViewItemView = (CLTimelineViewItemView *)[sender superview];
				CLTimelineViewItem *timelineViewItem = [timelineViewItemView timelineViewItemReference];
				CLTimelineView *timelineView = [timelineViewItem timelineViewReference];
				
				[timelineViewItem updateHeight];
				[timelineViewItem updateClassNames];
				[timelineView updateSubviewRects];
				[timelineView setNeedsDisplay:YES];
				
				// refresh again after timer fires to fix drawing errors
				if ([timelineViewItem heightUpdateTimer] != nil) {
					if ([[timelineViewItem heightUpdateTimer] isValid]) {
						[[timelineViewItem heightUpdateTimer] invalidate];
						[timelineViewItem setHeightUpdateTimer:nil];
					}
				}
				
				CLTimer *refreshTimer = [CLTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(webViewHeightTimerFired:) userInfo:timelineViewItem repeats:YES];
				[timelineViewItem setHeightUpdateTimer:refreshTimer];
				[timelineViewItem setHeightUpdateCount:0];
			}
		}
	}
}

- (void)webView:(CLWebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame {
	
	CLTabViewItem *tabViewItem = [sender tabViewItemReference];
	CLTabViewItemType tabType = [tabViewItem tabType];
	
	if (frame == [sender mainFrame]) {
		if (tabType == CLTimelineType) {			
			CLTimelineViewItemView *timelineViewItemView = (CLTimelineViewItemView *)[sender superview];
			CLTimelineViewItem *timelineViewItem = [timelineViewItemView timelineViewItemReference];
			CLTimelineView *timelineView = [timelineViewItem timelineViewReference];
			
			CLWebScriptHelper *webScriptHelper = [CLWebScriptHelper webScriptHelper];
			[webScriptHelper setWindowControllerReference:self];
			[webScriptHelper setTimelineViewReference:timelineView];
			[webScriptHelper setTimelineViewItemReference:timelineViewItem];
			
			[windowObject setValue:webScriptHelper forKey:@"webScriptHelper"];
		}
	}
}

- (WebView *)webView:(CLWebView *)sender createWebViewWithRequest:(NSURLRequest *)request {
	return [self openNewWebTabWith:request selectTab:YES];
}

- (void)webView:(WebView *)sender setFrame:(NSRect)frame {
	// DO NOT DELETE
	
	// this empty method declaration must be here.
	// this delegate method gets called when javascript tries to resize the window.
	// the default implementation actually resizes the window. since we don't want
	// any resize to happen, this method is empty.
}

- (void)webViewClose:(WebView *)sender {
	// AGAIN, DO NOT DELETE
	
	// this empty method declaration must be here.
	// the default implementation allows javascript to close windows
}

- (NSUInteger)webView:(CLWebView *)sender dragDestinationActionMaskForDraggingInfo:(id <NSDraggingInfo>)draggingInfo {
	
	CLTabViewItem *tabViewItem = [sender tabViewItemReference];
	CLTabViewItemType tabType = [tabViewItem tabType];
	
	if (tabType == CLTimelineType || tabType == CLClassicType) {
		return WebDragDestinationActionNone;
	}
	
	return WebDragDestinationActionAny;
}

- (NSArray *)webView:(CLWebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
	
	NSMutableArray *menuItemsToReturn = [NSMutableArray arrayWithArray:defaultMenuItems];
	
	NSURL *linkUrl = [element objectForKey:WebElementLinkURLKey];
	NSURL *imageUrl = [element objectForKey:WebElementImageURLKey];
	
	NSMutableArray *menuItemsToRemove = [NSMutableArray array];
	
	for (NSMenuItem *menuItem in menuItemsToReturn) {
		NSInteger menuItemTag = [menuItem tag];
		
		if (menuItemTag == WebMenuItemTagOpenLinkInNewWindow ||
			menuItemTag == WebMenuItemTagDownloadLinkToDisk ||
			menuItemTag == WebMenuItemTagOpenImageInNewWindow ||
			menuItemTag == WebMenuItemTagDownloadImageToDisk ||
			menuItemTag == WebMenuItemTagOpenFrameInNewWindow ||
			menuItemTag == WebMenuItemTagGoBack ||
			menuItemTag == WebMenuItemTagGoForward ||
			menuItemTag == WebMenuItemTagStop ||
			menuItemTag == WebMenuItemTagReload ||
			menuItemTag == WebMenuItemTagOpenWithDefaultApplication) {
			
			[menuItemsToRemove addObject:menuItem];
		}
	}
	
	for (NSMenuItem *menuItem in menuItemsToRemove) {
		[menuItemsToReturn removeObject:menuItem];
	}
	
	if (linkUrl != nil) {
		[menuItemsToReturn removeObjectAtIndex:0];
	}
	
	if (imageUrl != nil) {
		
		NSInteger insertPos = 0;
		
		if (linkUrl != nil) {
			insertPos = 2;
		}
		
		NSMenuItem *imageNewWindow = [[NSMenuItem alloc] initWithTitle:@"Open Image in New Window" action:@selector(webViewOpenLinkInNewWindow:) keyEquivalent:@""];
		[imageNewWindow setRepresentedObject:imageUrl];
		[menuItemsToReturn insertObject:imageNewWindow atIndex:insertPos];
		[imageNewWindow release];
		
		insertPos++;
		
		NSMenuItem *imageNewTab = [[NSMenuItem alloc] initWithTitle:@"Open Image in New Tab" action:@selector(webViewOpenLinkInNewTab:) keyEquivalent:@""];
		[imageNewTab setRepresentedObject:imageUrl];
		[menuItemsToReturn insertObject:imageNewTab atIndex:insertPos];
		[imageNewTab release];
	}
	
	if (linkUrl != nil) {
		
		NSMenuItem *linkNewWindow = [[NSMenuItem alloc] initWithTitle:@"Open Link in New Window" action:@selector(webViewOpenLinkInNewWindow:) keyEquivalent:@""];
		[linkNewWindow setRepresentedObject:linkUrl];
		[menuItemsToReturn insertObject:linkNewWindow atIndex:0];
		[linkNewWindow release];
		
		NSMenuItem *linkNewTab = [[NSMenuItem alloc] initWithTitle:@"Open Link in New Tab" action:@selector(webViewOpenLinkInNewTab:) keyEquivalent:@""];
		[linkNewTab setRepresentedObject:linkUrl];
		[menuItemsToReturn insertObject:linkNewTab atIndex:1];
		[linkNewTab release];
	}
	
	return menuItemsToReturn;
}

- (void)webViewHeightTimerFired:(CLTimer *)theTimer {
	CLTimelineViewItem *timelineViewItem = [theTimer userInfo];
	CLTimelineView *timelineView = [timelineViewItem timelineViewReference];
	
	[timelineViewItem updateHeight];
	[timelineView updateSubviewRects];
	[timelineView setNeedsDisplay:YES];
	
	[timelineViewItem setHeightUpdateCount:([timelineViewItem heightUpdateCount] + 1)];
	
	if ([timelineViewItem heightUpdateCount] >= TIMELINE_ITEM_REFRESH_COUNT) {
		[[timelineViewItem heightUpdateTimer] invalidate];
		[timelineViewItem setHeightUpdateTimer:nil];
	}
}

- (void)webViewOpenLinkInNewWindow:(NSMenuItem *)sender {
	NSURL *url = [sender representedObject];
	
	if (url != nil) {
		NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
		[delegate openNewWindowForUrlRequest:urlRequest];
	}
}

- (void)webViewOpenLinkInNewTab:(NSMenuItem *)sender {
	NSURL *url = [sender representedObject];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
	[self openNewWebTabWith:urlRequest selectTab:NO];
}

- (void)updateWebView:(WebView *)webView headlineFontName:(NSString *)headlineFontName headlineFontSize:(CGFloat)headlineFontSize bodyFontName:(NSString *)bodyFontName bodyFontSize:(CGFloat)bodyFontSize {
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"var head = document.getElementsByTagName('head')[0]; var style = document.createElement('style'); var rules = document.createTextNode(\"body {font: %fpt/1.45em '%@', sans-serif} th, td {font-size: %fpt} #postHeadline {font: %fpt '%@', sans-serif}\"); style.type = 'text/css'; style.appendChild(rules); head.appendChild(style);", bodyFontSize, bodyFontName, bodyFontSize, headlineFontSize, headlineFontName]];
}


# pragma mark CLTabView mouse tracking

- (void)mouseDown:(NSEvent *)theEvent {
	
	NSPoint eventLocation = [theEvent locationInWindow];
	NSPoint localPoint = [tabView convertPoint:eventLocation fromView:nil];
	NSRect addButtonRect = [tabView addButtonRect];
	
	if (localPoint.y <= [tabView frame].size.height) {
		BOOL didClickTab = NO;
		BOOL didClickAddButton = NO;
		
		NSInteger tabIndex = [self findTabIndexForEvent:theEvent];
		
		if (tabIndex != NSNotFound) {
			
			// check to see if they clicked on a close button
			NSPoint closePoint = [tabView convertPoint:eventLocation fromView:nil];
			
			if (NSPointInRect(closePoint, [[[tabView tabViewItems] objectAtIndex:tabIndex] tabCloseRect])) {
				[self removeTabViewItem:[[tabView tabViewItems] objectAtIndex:tabIndex]];
			} else {
				[self selectTabViewItemAtIndex:tabIndex];
				
				if (dragDelayTimer != nil) {
					if ([dragDelayTimer isValid]) {
						[dragDelayTimer invalidate];
					}
					[self setDragDelayTimer:nil];
				}
				
				for (CLTabViewItem *tabViewItem in [tabView tabViewItems]) {
					if ([tabViewItem isLoading] && [[tabViewItem spinner] isHidden] == NO) {
						[[tabViewItem spinner] setHidden:YES];
					}
				}
				
				[tabView setDragTabViewItem:[[tabView tabViewItems] objectAtIndex:tabIndex]];
				[self setDragTabIndex:tabIndex];
				[self setDragTabOriginalX:[[[tabView tabViewItems] objectAtIndex:tabIndex] rect].origin.x];
				NSInteger mouseX = (NSInteger)([NSEvent mouseLocation].x);
				[self setDragMouseOriginalX:mouseX];
				[self setDragShouldStart:NO];
				
				CLTimer *dragTimer = [CLTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(dragDelayTimerFired:) userInfo:nil repeats:NO];
				[self setDragDelayTimer:dragTimer];
			}
			
			didClickTab = YES;
		} else {
			if (localPoint.x >= addButtonRect.origin.x && localPoint.x <= (addButtonRect.origin.x + addButtonRect.size.width)) {
				[self openNewTab];
				didClickAddButton = YES;
			}
		}
		
		// open a new tab if they double clicked on the tab bar
		if (didClickTab == NO && didClickAddButton == NO && [theEvent clickCount] == 2) {
			[self openNewTab];
		}
	}
}

- (void)mouseDragged:(NSEvent *)theEvent {
	
	// check to see if we are in the middle of a drag operation
	if (dragTabIndex >= 0 && dragShouldStart) {
		NSInteger mouseX = (int)([NSEvent mouseLocation].x);
		NSInteger dragDistance = mouseX - dragMouseOriginalX;
		NSInteger tabNewX = dragTabOriginalX + dragDistance;
		NSUInteger tabWidth = [[tabView dragTabViewItem] rect].size.width;
		
		if (tabNewX < 0) {
			tabNewX = 0;
		}
		
		if (tabNewX > ([tabView frame].size.width - tabWidth - TABVIEW_ADD_BUTTON_WIDTH + 1)) {
			tabNewX = [tabView frame].size.width - tabWidth - TABVIEW_ADD_BUTTON_WIDTH + 1;
		}
		
		NSRect tabOldRect = [[tabView dragTabViewItem] rect];
		NSRect tabNewRect = NSMakeRect(tabNewX, tabOldRect.origin.y, tabOldRect.size.width, tabOldRect.size.height);
		
		[[tabView dragTabViewItem] setRect:tabNewRect];
		[[tabView dragTabViewItem] setTabCloseRect:NSMakeRect(tabNewRect.origin.x + TAB_CLOSE_X_INDENT, tabNewRect.origin.y + TAB_CLOSE_Y_INDENT, TAB_CLOSE_WIDTH, TAB_CLOSE_HEIGHT)];
		
		// figure out if tabs need to be shifted around
		if (dragTabIndex > 0) {
			CLTabViewItem *leftTab = [[tabView tabViewItems] objectAtIndex:(dragTabIndex - 1)];
			NSRect leftRect = [leftTab rect];
			
			if ([leftTab isSliding] == NO) {
				
				// if the tab being dragged is covering up more than half of the tab to the left
				if (tabNewX < (leftRect.origin.x + (tabWidth / 2) + DRAG_PADDING)) {
					
					[leftTab slideToXPosition:(leftRect.origin.x + tabWidth) animate:YES];
					
					[[tabView tabViewItems] exchangeObjectAtIndex:dragTabIndex withObjectAtIndex:(dragTabIndex - 1)];
					dragTabIndex -= 1;
				}
			}
		}
		
		if (dragTabIndex < (NSInteger)([self numberOfTabViewItems] - 1)) {
			CLTabViewItem *rightTab = [[tabView tabViewItems] objectAtIndex:(dragTabIndex + 1)];
			NSRect rightRect = [rightTab rect];
			
			if ([rightTab isSliding] == NO) {
				
				// if the tab being dragged is covering up more than half of the tab to the right
				if (tabNewX > (rightRect.origin.x - (tabWidth / 2) + DRAG_PADDING)) {
					
					[rightTab slideToXPosition:(rightRect.origin.x - tabWidth) animate:YES];
					
					[[tabView tabViewItems] exchangeObjectAtIndex:dragTabIndex withObjectAtIndex:(dragTabIndex + 1)];
					dragTabIndex += 1;
				}
			}
		}
		
		[tabView setNeedsDisplay:YES];
	}
}

- (void)mouseUp:(NSEvent *)theEvent {
	
	for (CLTabViewItem *tabViewItem in [tabView tabViewItems]) {
		if ([tabViewItem isLoading] && [[tabViewItem spinner] isHidden]) {
			[[tabViewItem spinner] setHidden:YES];
		}
	}
	
	[tabView setDragTabViewItem:nil];
	[self setDragTabIndex:-1];
	[self setDragTabOriginalX:0];
	[self setDragMouseOriginalX:0];
	[self setDragShouldStart:NO];
	
	if (dragDelayTimer != nil) {
		if ([dragDelayTimer isValid]) {
			[dragDelayTimer invalidate];
		}
		[self setDragDelayTimer:nil];
	}
	
	[self updateTabRectsAndTrackingRects:YES];
	[self updateAddButtonRectAndTrackingRect:YES];
	[tabView setNeedsDisplay:YES];
}

// this only applies to the add button
- (void)mouseEntered:(NSEvent *)theEvent {
	[tabView setIsAddButtonHover:YES];
	[tabView setNeedsDisplay:YES];
}

// this only applies to the add button
- (void)mouseExited:(NSEvent *)theEvent {
	[tabView setIsAddButtonHover:NO];
	[tabView setNeedsDisplay:YES];
}

// this is a helper method, not an event method
- (NSInteger)findTabIndexForEvent:(NSEvent *)theEvent {
	
	NSInteger tabIndex = NSNotFound;
	
	NSPoint eventLocation = [theEvent locationInWindow];
	NSPoint localPoint = [tabView convertPoint:eventLocation fromView:nil];
	
	NSInteger i = 0;
	
	// figure out if the event happened over a tab
	for (CLTabViewItem *tabViewItem in [tabView tabViewItems]) {
		if (localPoint.x >= [tabViewItem rect].origin.x && localPoint.x <= ([tabViewItem rect].origin.x + [tabViewItem rect].size.width)) {
			tabIndex = i;
			break;
		}
		
		i++;
	}
	
	return tabIndex;
}

- (void)dragDelayTimerFired:(CLTimer *)theTimer {
	[self setDragShouldStart:YES];
	
	[self setDragDelayTimer:nil];
}

- (void)updateTabRectsAndTrackingRects:(BOOL)flag {
	
	CGFloat currentOffset = 0.0;
	NSUInteger tabWidth = (NSUInteger)(([tabView frame].size.width - TABVIEW_ADD_BUTTON_WIDTH) / [self numberOfTabViewItems]);
	
	if (tabWidth > MAX_TAB_WIDTH) {
		tabWidth = MAX_TAB_WIDTH;
	}
	
	// to make the ui look nice, some tabs will be 1 pixel wider than others
	NSUInteger extraPixels = [tabView frame].size.width - (tabWidth * [self numberOfTabViewItems]) - TABVIEW_ADD_BUTTON_WIDTH + 1;
	NSUInteger numUpdated = 0;
	
	for (CLTabViewItem *tabViewItem in [tabView tabViewItems]) {
		NSRect newRect;
		
		if (numUpdated < extraPixels) {
			newRect = NSMakeRect(currentOffset, 0, tabWidth + 1, TAB_BAR_HEIGHT);
			currentOffset += 1;
		} else {
			newRect = NSMakeRect(currentOffset, 0, tabWidth, TAB_BAR_HEIGHT);
		}
		
		[tabViewItem setRect:newRect];
		
		// close button
		[tabViewItem setTabCloseRect:NSMakeRect(newRect.origin.x + TAB_CLOSE_X_INDENT, newRect.origin.y + TAB_CLOSE_Y_INDENT, TAB_CLOSE_WIDTH, TAB_CLOSE_HEIGHT)];
		
		if (flag) {
			[tabViewItem updateTrackingRects];
		}
		
		currentOffset += tabWidth;
		numUpdated += 1;
	}
}

- (void)updateAddButtonRectAndTrackingRect:(BOOL)flag {
	
	[tabView setAddButtonRect:NSMakeRect([tabView frame].size.width - TABVIEW_ADD_BUTTON_WIDTH, 0, TABVIEW_ADD_BUTTON_WIDTH, [tabView frame].size.height)];
	
	if (addButtonTrackingTag != -1) {
		[tabView removeTrackingRect:addButtonTrackingTag];
		[self setAddButtonTrackingTag:-1];
	}
	
	if (flag) {
		NSTrackingRectTag trackTag = [tabView addTrackingRect:[tabView addButtonRect] owner:self userData:nil assumeInside:NO];
		[self setAddButtonTrackingTag:trackTag];
	}
}


# pragma mark NSSplitViewDelegate

- (BOOL)splitView:(NSSplitView *)aSplitView shouldAdjustSizeOfSubview:(NSView *)subview {
	if (subview == [[aSplitView subviews] objectAtIndex:0]) {
		return NO;
	}
	
	return YES;
}

- (BOOL)splitView:(NSSplitView *)aSplitView canCollapseSubview:(NSView *)subview {
	if (aSplitView == splitView) {
		if (subview == [[aSplitView subviews] objectAtIndex:0]) {
			return YES;
		}
	}
	
	return NO;
}

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex {
	return 125.0;
}

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex {
	if (aSplitView == splitView) {
		return 350.0;
	}
	
	return proposedMax;
}

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
	NSSplitView *aSplitView = [aNotification object];
	
	if (aSplitView == splitView) {
		if ([[tabView selectedTabViewItem] tabType] == CLTimelineType) {
			CLTimelineView *timelineView = [[tabView selectedTabViewItem] timelineView];
			
			BOOL subviewRectsNeedUpdating = NO;
			
			for (CLTimelineViewItem *timelineViewItem in [timelineView timelineViewItems]) {
				if ([timelineViewItem updateHeight]) {
					subviewRectsNeedUpdating = YES;
				}
			}
			
			if (subviewRectsNeedUpdating) {
				[timelineView updateSubviewRects];
				[timelineView setNeedsDisplay:YES];
			}
		}
	}
}


#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(CLTableView *)aTableView {
	CLClassicView *classicView = [aTableView classicViewReference];
	return [[classicView posts] count];
}

- (id)tableView:(CLTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	CLClassicView *classicView = [aTableView classicViewReference];
	return [[[classicView posts] objectAtIndex:rowIndex] title];
}


#pragma mark NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	CLTableView *tableView = [aNotification object];
	CLClassicView *classicView = [tableView classicViewReference];
	CLPost *previousSelection = [classicView displayedPost];
	CLPost *currentSelection = nil;
	NSInteger selectedRow = [tableView selectedRow];
	
	if ([classicView shouldIgnoreSelectionChange] == NO || selectedRow >= 0) {
		if (selectedRow >= 0) {
			currentSelection = [[classicView posts] objectAtIndex:selectedRow];
			
			if (currentSelection != previousSelection) {
				NSString *headlineFontName = [delegate preferenceHeadlineFontName];
				CGFloat headlineFontSize = [delegate preferenceHeadlineFontSize];
				NSString *bodyFontName = [delegate preferenceBodyFontName];
				CGFloat bodyFontSize = [delegate preferenceBodyFontSize];
				
				[classicView updateUsingPost:currentSelection headlineFontName:headlineFontName headlineFontSize:headlineFontSize bodyFontName:bodyFontName bodyFontSize:bodyFontSize];
			}
			
			if ([currentSelection isRead] == NO) {
				[delegate markPostWithDbIdAsRead:[currentSelection dbId]];
			}
			
		} else {
			[classicView setDisplayedPost:nil];
			[[[classicView webView] mainFrame] loadHTMLString:@"" baseURL:nil];
		}
	}
	
	[classicView setShouldIgnoreSelectionChange:NO];
	
	[tableView setNeedsDisplay:YES];
	
	[delegate classicViewSelectionDidChange];
}

- (void)tableView:(CLTableView *)aTableView willDisplayCell:(CLTableViewTextFieldCell *)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	[aCell setDelegate:self];
	[aCell setRowIndex:rowIndex];
	[aCell setTableViewReference:aTableView];
}

- (BOOL)tableView:(CLTableView *)aTableView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return NO;
}


#pragma mark CLTableViewTextFieldCellDelegate

- (CLPost *)tableViewTextFieldCell:(CLTableViewTextFieldCell *)tableViewTextFieldCell postForRow:(NSInteger)rowIndex {
	CLTableView *tableView = [tableViewTextFieldCell tableViewReference];
	CLClassicView *classicView = [tableView classicViewReference];
	CLPost *post = [[classicView posts] objectAtIndex:rowIndex];
	
	// update feed title
	if (post != nil && [post feedDbId] > 0) {
		CLSourceListFeed *feed = [delegate feedForDbId:[post feedDbId]];
		
		if (feed != nil) {
			[post setFeedTitle:[feed title]];
		}
	}
	
	return post;
}

@end
