//
//  CLWindowController.h
//  Syndication
//
//  Created by Calvin Lough on 2/17/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "CLTabViewDelegate.h"
#import "CLTableViewTextFieldCellDelegate.h"
#import "CLWindowControllerDelegate.h"

@class CLActivityView;
@class CLClassicView;
@class CLFeedSheetController;
@class CLPost;
@class CLSourceList;
@class CLSourceListFeed;
@class CLSourceListFolder;
@class CLSourceListItem;
@class CLTabView;
@class CLTabViewItem;
@class CLTimelineView;
@class CLTimelineViewItem;
@class CLTimer;
@class CLWebView;

typedef enum {CLTimelineViewMode, CLClassicViewMode} CLViewMode;

@interface CLWindowController : NSWindowController <CLTabViewDelegate, CLTableViewTextFieldCellDelegate, NSOutlineViewDataSource, 
		NSOutlineViewDelegate, NSSplitViewDelegate, NSTableViewDataSource, NSTableViewDelegate> {
	id <CLWindowControllerDelegate> delegate;
	CLViewMode viewMode;
	NSMutableArray *subscriptionList;
	CLSourceList *sourceList;
	CLSourceListItem *sourceListRoot;
	CLSourceListItem *sourceListNewItems;
	CLSourceListItem *sourceListStarredItems;
	CLSourceListItem *sourceListSubscriptions;
	CLSourceListItem *sourceListSelectedItem;
	CLTabView *tabView;
	NSSplitView *splitView;
	NSSegmentedControl *viewSegmentedControl;
	NSTrackingRectTag addButtonTrackingTag;
	NSInteger dragTabIndex;
	NSInteger dragTabOriginalX;
	NSInteger dragMouseOriginalX;
	BOOL dragShouldStart;
	CLTimer *dragDelayTimer;
	CLFeedSheetController *feedSheetController;
	NSTextField *feedSheetTextField;
	NSButton *feedSheetGoogleCheckbox;
	CLSourceListItem *sourceListDragItem;
	NSMenu *sourceListContextMenu;
	NSSearchField *searchField;
	CLTimer *classicViewRefreshTimer;
	CLActivityView *activityView;
	NSInteger lastClassicViewDividerPosition;
	NSInteger lastWindowChange;
}

@property (assign, nonatomic) id <CLWindowControllerDelegate> delegate;
@property (assign, nonatomic) CLViewMode viewMode;
@property (retain, nonatomic) NSMutableArray *subscriptionList;
@property (assign, nonatomic) IBOutlet CLSourceList *sourceList;
@property (retain, nonatomic) CLSourceListItem *sourceListRoot;
@property (retain, nonatomic) CLSourceListItem *sourceListNewItems;
@property (retain, nonatomic) CLSourceListItem *sourceListStarredItems;
@property (retain, nonatomic) CLSourceListItem *sourceListSubscriptions;
@property (retain, nonatomic) CLSourceListItem *sourceListSelectedItem;
@property (assign, nonatomic) IBOutlet CLTabView *tabView;
@property (assign, nonatomic) IBOutlet NSSplitView *splitView;
@property (assign, nonatomic) IBOutlet NSSegmentedControl *viewSegmentedControl;
@property (assign, nonatomic) NSTrackingRectTag addButtonTrackingTag;
@property (assign, nonatomic) NSInteger dragTabIndex;
@property (assign, nonatomic) NSInteger dragTabOriginalX;
@property (assign, nonatomic) NSInteger dragMouseOriginalX;
@property (assign, nonatomic) BOOL dragShouldStart;
@property (retain, nonatomic) CLTimer *dragDelayTimer;
@property (assign, nonatomic) IBOutlet CLFeedSheetController *feedSheetController;
@property (assign, nonatomic) IBOutlet NSTextField *feedSheetTextField;
@property (assign, nonatomic) IBOutlet NSButton *feedSheetGoogleCheckbox;
@property (assign, nonatomic) CLSourceListItem *sourceListDragItem;
@property (assign, nonatomic) IBOutlet NSMenu *sourceListContextMenu;
@property (assign, nonatomic) IBOutlet NSSearchField *searchField;
@property (retain, nonatomic) CLTimer *classicViewRefreshTimer;
@property (assign, nonatomic) IBOutlet CLActivityView *activityView;
@property (assign, nonatomic) NSInteger lastClassicViewDividerPosition;
@property (assign, nonatomic) NSInteger lastWindowChange;

- (void)updateFirstResponder;
- (void)setupSourceList;
- (void)refreshSourceList;
- (NSInteger)updateBadgeValuesFor:(NSMutableArray *)children;
- (void)refreshTabsForAncestorsOf:(CLSourceListItem *)item;
- (void)refreshTabsFor:(CLSourceListItem *)item;
- (void)refreshSearchTabs;
- (void)loadPostsIntoTimeline:(CLTimelineView *)timeline orClassicView:(CLClassicView *)classicView;
- (void)loadPostsIntoTimeline:(CLTimelineView *)timeline orClassicView:(CLClassicView *)classicView fromRange:(NSRange)range atBottom:(BOOL)bottom;
- (void)addPost:(CLPost *)post toTimeline:(CLTimelineView *)timeline atIndex:(NSInteger)indexLoc;
- (IBAction)addSubscription:(id)sender;
- (IBAction)doAddNewSubscription:(id)sender;
- (IBAction)addFolder:(id)sender;
- (void)back;
- (void)forward;
- (IBAction)refresh:(id)sender;
- (IBAction)view:(id)sender;
- (void)changeToClassicViewMode;
- (void)changeToTimelineViewMode;
- (void)changeWidthOfWindowBy:(NSInteger)change;
- (IBAction)search:(id)sender;
- (void)addSubscriptionForUrlString:(NSString *)url addToGoogle:(BOOL)addToGoogle;
- (BOOL)selectSourceListItem:(CLSourceListItem *)item;
- (void)editSourceListItem:(CLSourceListItem *)item;
- (void)redrawSourceListItem:(CLSourceListItem *)item;
- (void)timelineView:(CLTimelineView *)timelineView timelineViewItem:(CLTimelineViewItem *)timelineViewItem scrollToAnchor:(NSString *)anchor;
- (void)classicView:(CLClassicView *)classicView scrollToAnchor:(NSString *)anchor;
- (CGFloat)yPositionOfAnchor:(NSString *)anchor inWebView:(CLWebView *)webView;
- (void)updateWindowTitle;
- (void)updateViewSwitchEnabled;
- (void)classicViewRefreshTimerFired:(CLTimer *)theTimer;
- (void)clockDidChange:(NSNotification *)notification;

- (void)menuNeedsUpdate:(NSMenu *)menu;
- (void)sourceListOpenInNewTab:(NSMenuItem *)sender;
- (void)sourceListOpenInNewWindow:(NSMenuItem *)sender;
- (void)sourceListRefresh:(id)sender;
- (void)sourceListMarkAllAsRead:(NSMenuItem *)sender;
- (void)sourceListRename:(id)sender;
- (void)sourceListDelete:(id)sender;
- (void)sourceListDeleteAlertDidEnd:(NSAlert *)theAlert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)sourceListGoogleDeleteAlertDidEnd:(NSAlert *)theAlert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (NSInteger)numberFromGoogleForItemOrDescendents:(CLSourceListItem *)item;

- (void)addTabViewItem:(CLTabViewItem *)tabViewItem;
- (void)addTimelineTabViewItem:(CLTabViewItem *)tabViewItem;
- (void)addClassicTabViewItem:(CLTabViewItem *)tabViewItem;
- (void)addWebTabViewItem:(CLTabViewItem *)tabViewItem;
- (void)createViewForTimelineTab:(CLTabViewItem *)tabViewItem;
- (void)createViewForClassicTab:(CLTabViewItem *)tabViewItem;
- (void)createViewForWebTab:(CLTabViewItem *)tabViewItem;
- (void)removeViewForTimelineTab:(CLTabViewItem *)tabViewItem;
- (void)removeViewForClassicTab:(CLTabViewItem *)tabViewItem;
- (void)removeViewForWebTab:(CLTabViewItem *)tabViewItem;
- (void)openNewTab;
- (void)openNewEmptyTab;
- (void)openNewTabFor:(CLSourceListItem *)subscription selectTab:(BOOL)flag;
- (CLWebView *)openNewWebTabWith:(NSURLRequest *)request selectTab:(BOOL)flag;
- (void)openInTab:(CLTabViewItem *)tabViewItem item:(CLSourceListItem *)item orQuery:(NSString *)queryString;
- (void)openItemInCurrentTab:(CLSourceListItem *)item orQuery:(NSString *)queryString;
- (void)reloadContentForTab:(CLTabViewItem *)tabViewItem;
- (void)updateViewVisibilityForTab:(CLTabViewItem *)tabViewItem;
- (void)closeTab;
- (void)closeAllTabsForFeed:(CLSourceListFeed *)feed;
- (void)closeAllTabsForFolderOrDescendent:(CLSourceListFolder *)folder;
- (void)removeTabViewItem:(CLTabViewItem *)tabViewItem;
- (NSUInteger)numberOfTabViewItems;
- (NSUInteger)indexOfTabViewItem:(CLTabViewItem *)tabViewItem;
- (void)selectTabViewItem:(CLTabViewItem *)tabViewItem;
- (void)selectTabViewItemAtIndex:(NSUInteger)index;
- (void)selectFirstTabViewItem;
- (void)selectLastTabViewItem;
- (void)selectNextTabViewItem;
- (void)selectPreviousTabViewItem;
- (void)showOrHideTabBar;

- (void)setSelectedItem:(CLTimelineViewItem *)item forTimelineView:(CLTimelineView *)timelineView;
- (void)scrollTimelineViewItem:(CLTimelineViewItem *)item toTopOfTimelineView:(CLTimelineView *)timelineView;
- (void)selectNextItemForTimelineView:(CLTimelineView *)timelineView;
- (void)selectPreviousItemForTimelineView:(CLTimelineView *)timelineView;
- (void)userSelectItem:(CLTimelineViewItem *)item forTimelineView:(CLTimelineView *)timelineView;
- (void)selectItemAtTopOfTimelineView:(CLTimelineView *)timelineView;
- (void)timelineClipViewDidScroll:(NSNotification *)notification;
- (void)checkIfTimelineNeedsToLoadMoreContent:(CLTimelineView *)timelineView;
- (void)checkIfTimelineNeedsToUnloadContent:(CLTimelineView *)timelineView;
- (void)classicViewTableViewDidScroll:(NSNotification *)notification;
- (void)checkIfClassicViewNeedsToLoadMoreContent:(CLClassicView *)classicView;
- (void)checkIfClassicViewNeedsToUnloadContent:(CLClassicView *)classicView;
- (NSInteger)numberOfTimelineViewItemsPerScreenOfClipView:(NSClipView *)clipView;

- (void)windowDidResize:(NSNotification *)notification;
- (void)windowDidEndLiveResize:(NSNotification *)notification;
- (void)windowDidBecomeMain:(NSNotification *)notification;
- (void)windowDidResignMain:(NSNotification *)notification;

- (void)webViewHeightTimerFired:(CLTimer *)theTimer;
- (void)webViewOpenLinkInNewWindow:(NSMenuItem *)sender;
- (void)webViewOpenLinkInNewTab:(NSMenuItem *)sender;
- (void)updateWebView:(WebView *)webView headlineFontName:(NSString *)headlineFontName headlineFontSize:(CGFloat)headlineFontSize bodyFontName:(NSString *)bodyFontName bodyFontSize:(CGFloat)bodyFontSize;

- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseDragged:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;
- (NSInteger)findTabIndexForEvent:(NSEvent *)theEvent;
- (void)dragDelayTimerFired:(CLTimer *)theTimer;
- (void)updateTabRectsAndTrackingRects:(BOOL)flag;
- (void)updateAddButtonRectAndTrackingRect:(BOOL)flag;

@end
