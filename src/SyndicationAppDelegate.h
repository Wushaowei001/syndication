//
//  SyndicationAppDelegate.h
//  Syndication
//
//  Created by Calvin Lough on 12/30/10.
//  Copyright 2010 Calvin Lough. All rights reserved.
//

#import "CLFeedParserOperationDelegate.h"
#import "CLFeedRequestDelegate.h"
#import "CLIconRefreshOperationDelegate.h"
#import "CLPreferencesWindowDelegate.h"
#import "CLRequest.h"
#import "CLWindowControllerDelegate.h"

@class CLFeedParserOperation;
@class CLPost;
@class CLPreferencesWindow;
@class CLSourceListFeed;
@class CLSourceListFolder;
@class CLSourceListItem;
@class CLTimelineViewItem;
@class CLTimer;
@class CLXMLNode;
@class FMDatabase;

@interface SyndicationAppDelegate : NSObject <CLFeedParserOperationDelegate, CLFeedRequestDelegate, CLIconRefreshOperationDelegate,
		CLPreferencesWindowDelegate, CLWindowControllerDelegate, NSApplicationDelegate, NSToolbarDelegate> {
	NSMutableArray *subscriptionList;
	NSMutableDictionary *feedLookupDict;
	NSOperationQueue *operationQueue;
	CLTimer *feedSyncTimer;
	NSMutableArray *feedsToSync;
	NSMutableArray *feedRequests;
	NSInteger numberOfActiveParseOps;
	NSMutableArray *requestQueue;
	BOOL requestInProgress;
	CLRequestType activeRequestType;
	NSMutableArray *iconRefreshTimers;
	NSMutableArray *activityViewFeeds;
	NSMutableArray *windowControllers;
	NSMenu *subscriptionsMenu;
	NSInteger totalUnread;
	CLPreferencesWindow *preferencesWindow;
	NSToolbar *preferencesToolbar;
	NSTabView *preferencesTabView;
	NSPopUpButton *preferencesFeedReaderPopUp;
	NSInteger preferencesContentHeight;
	NSInteger preferenceCheckForNewArticles;
	NSInteger preferenceRemoveArticles;
	NSInteger preferenceMarkArticlesAsRead;
	BOOL preferenceDisplayUnreadCountInDock;
	NSTextField *preferencesHeadlineTextField;
	NSString *preferenceHeadlineFontName;
	CGFloat preferenceHeadlineFontSize;
	NSTextField *preferencesBodyTextField;
	NSString *preferenceBodyFontName;
	CGFloat preferenceBodyFontSize;
	BOOL isFirstWindow;
	NSWindow *opmlLoadingWindow;
	NSProgressIndicator *opmlLoadingProgressIndicator;
	BOOL inLiveResize;
	NSWindow *windowForUpdate;
	BOOL hasFinishedLaunching;
	NSString *feedEventString;
}

@property (retain, nonatomic) NSMutableArray *subscriptionList;
@property (retain, nonatomic) NSMutableDictionary *feedLookupDict;
@property (retain, nonatomic) NSOperationQueue *operationQueue;
@property (retain, nonatomic) CLTimer *feedSyncTimer;
@property (retain, nonatomic) NSMutableArray *feedsToSync;
@property (retain, nonatomic) NSMutableArray *feedRequests;
@property (assign, nonatomic) NSInteger numberOfActiveParseOps;
@property (retain, nonatomic) NSMutableArray *requestQueue;
@property (assign, nonatomic) BOOL requestInProgress;
@property (assign, nonatomic) CLRequestType activeRequestType;
@property (retain, nonatomic) NSMutableArray *iconRefreshTimers;
@property (retain, nonatomic) NSMutableArray *activityViewFeeds;
@property (retain, nonatomic) NSMutableArray *windowControllers;
@property (assign, nonatomic) IBOutlet NSMenu *subscriptionsMenu;
@property (assign, nonatomic) NSInteger totalUnread;
@property (assign, nonatomic) IBOutlet CLPreferencesWindow *preferencesWindow;
@property (assign, nonatomic) IBOutlet NSToolbar *preferencesToolbar;
@property (assign, nonatomic) IBOutlet NSTabView *preferencesTabView;
@property (assign, nonatomic) IBOutlet NSPopUpButton *preferencesFeedReaderPopUp;
@property (assign, nonatomic) NSInteger preferencesContentHeight;
@property (assign, nonatomic) NSInteger preferenceCheckForNewArticles;
@property (assign, nonatomic) NSInteger preferenceRemoveArticles;
@property (assign, nonatomic) NSInteger preferenceMarkArticlesAsRead;
@property (assign, nonatomic) BOOL preferenceDisplayUnreadCountInDock;
@property (assign, nonatomic) IBOutlet NSTextField *preferencesHeadlineTextField;
@property (retain, nonatomic) NSString *preferenceHeadlineFontName;
@property (assign, nonatomic) CGFloat preferenceHeadlineFontSize;
@property (assign, nonatomic) IBOutlet NSTextField *preferencesBodyTextField;
@property (retain, nonatomic) NSString *preferenceBodyFontName;
@property (assign, nonatomic) CGFloat preferenceBodyFontSize;
@property (assign, nonatomic) BOOL isFirstWindow;
@property (assign, nonatomic) IBOutlet NSWindow *opmlLoadingWindow;
@property (assign, nonatomic) IBOutlet NSProgressIndicator *opmlLoadingProgressIndicator;
@property (assign, nonatomic) BOOL inLiveResize;
@property (retain, nonatomic) NSWindow *windowForUpdate;
@property (assign, nonatomic) BOOL hasFinishedLaunching;
@property (retain, nonatomic) NSString *feedEventString;

+ (BOOL)isSourceListItem:(CLSourceListItem *)item descendentOf:(CLSourceListItem *)parent;
+ (void)changeBadgeValueBy:(NSInteger)value forItem:(CLSourceListItem *)item;
+ (void)changeBadgeValuesBy:(NSInteger)value forAncestorsOfItem:(CLSourceListItem *)item;
+ (void)clearBadgeValuesForItemAndDescendents:(CLSourceListItem *)item;
+ (void)addToTimelineUnreadItemsDict:(CLTimelineViewItem *)timelineViewItem;
+ (void)removeFromTimelineUnreadItemsDict:(CLTimelineViewItem *)timelineViewItem;
+ (NSString *)miscellaneousValueForKey:(NSString *)key;
+ (void)miscellaneousSetValue:(NSString *)value forKey:(NSString *)key;

- (BOOL)tableExists:(NSString *)tableName inDb:(FMDatabase *)db;
- (void)runDatabaseUpdateOnBackgroundThread:(NSString *)queryString, ... NS_REQUIRES_NIL_TERMINATION;
- (void)runDatabaseUpdatesOnBackgroundThread:(NSArray *)queries;
- (void)loadFromDatabase;
- (void)recursivelyLoadChildrenOf:(CLSourceListFolder *)folder usingDatabaseHandle:(FMDatabase *)db;
- (void)updateFeedSyncStatus;
- (void)queueSyncRequestForSpecificFeeds:(NSMutableArray *)feeds;
- (void)queueDeleteHiddenRequest;
- (void)startRequestIfNoneInProgress;
- (void)startFeedRequests;
- (void)queueIconRefreshOperationFor:(CLSourceListFeed *)feed;
- (void)queueDeleteHiddenOperation;
- (void)cancelAllActivityFor:(CLSourceListItem *)item;
- (void)cancelAnyTimersIn:(NSArray *)timerList forItem:(CLSourceListItem *)item;
- (void)processNewPosts:(NSArray *)newPosts forFeed:(CLSourceListFeed *)feed;
- (void)addPostsToAllWindows:(NSArray *)posts forFeed:(CLSourceListFeed *)feed orNewItems:(BOOL)newItems orStarredItems:(BOOL)starredItems;
- (void)removeStarredPostFromAllWindows:(CLPost *)post;
- (void)markIconAsRefreshedAndStartTimer:(CLSourceListFeed *)feed;
- (NSInteger)dbIdForUrlString:(NSString *)urlString;
- (CLSourceListFeed *)feedForUrlString:(NSString *)urlString;
- (void)timeToSyncFeeds:(CLTimer *)timer;
- (void)timeToAddFeedToIconQueue:(CLTimer *)timer;
- (void)closeAllTabsForSourceListItem:(CLSourceListItem *)subscription;
- (void)markViewItemsAsReadForPostDbId:(NSInteger)postDbId;
- (NSString *)OPMLString;
- (NSString *)OPMLStringForItem:(CLSourceListItem *)item indentLevel:(NSUInteger)indentLevel;
- (void)processOPML:(CLXMLNode *)rootNode;
- (void)updateDockTile;
- (void)refreshTabsForNewItems;
- (void)refreshTabsForStarredItems;
- (void)refreshSearchTabs;
- (void)refreshAllActivityViews;
- (CLPost *)postForDbId:(NSInteger)dbId;
- (void)sortSourceListHelper:(NSMutableArray *)children;
- (void)didDeleteFeed:(CLSourceListFeed *)feed;
- (void)didDeleteFolder:(CLSourceListFolder *)folder;
- (void)refreshSourceListFeed:(CLSourceListFeed *)feed;
- (void)refreshSourceListFolder:(CLSourceListFolder *)folder;
- (void)removeOldArticles;
- (void)markArticlesAsRead;
- (void)addStarToPost:(CLPost *)post;
- (void)removeStarFromPost:(CLPost *)post;

- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)newWindow:(id)sender;
- (IBAction)newTab:(id)sender;
- (IBAction)closeWindow:(id)sender;
- (IBAction)closeTab:(id)sender;
- (IBAction)openLink:(id)sender;
- (IBAction)openLinkInBrowser:(id)sender;
- (IBAction)importOPML:(id)sender;
- (IBAction)exportOPML:(id)sender;
- (IBAction)classicView:(id)sender;
- (IBAction)timelineView:(id)sender;
- (IBAction)refreshSubscriptions:(id)sender;
- (IBAction)reloadPage:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)forward:(id)sender;
- (IBAction)addSubscription:(id)sender;
- (IBAction)addFolder:(id)sender;
- (IBAction)addStar:(id)sender;
- (IBAction)removeStar:(id)sender;
- (IBAction)selectNextTab:(id)sender;
- (IBAction)selectPreviousTab:(id)sender;
- (IBAction)acknowledgments:(id)sender;
- (void)openSubscription:(NSMenuItem *)sender;
- (void)openNewItems:(NSMenuItem *)sender;
- (void)openStarredItems:(NSMenuItem *)sender;

- (BOOL)isContentWindow:(NSWindow *)window;
- (void)updateMenuItems;
- (void)updateMenuItemsUsingWindow:(NSWindow *)window;
- (void)windowDidBecomeKey:(NSNotification *)notification;
- (void)windowDidResignKey:(NSNotification *)notification;
- (void)windowIsClosing:(NSNotification *)notification;
- (void)updateSubscriptionsMenu;
- (void)addSubscriptionsFrom:(NSMutableArray *)array toMenu:(NSMenu *)menu;

- (void)toolbarItemSelected:(NSToolbarItem *)toolbarItem;
- (IBAction)preferencesSelectHeadlineFont:(id)sender;
- (IBAction)preferencesSelectBodyFont:(id)sender;
- (void)preferencesSetDefaultFeedReader:(NSMenuItem *)menuItem;
- (void)preferencesSelectOtherApplication:(NSMenuItem *)menuItem;
- (void)updatePreferencesFeedReaderPopUp;
- (void)updatePreferencesFontTextFields;
- (void)updateContentFonts;
- (void)defaultsChanged:(NSNotification *)notification;
- (void)readPreferencesAndUpdate;

- (void)handleFeedEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;

- (void)windowWillStartLiveResize:(NSNotification *)notification;
- (void)windowDidEndLiveResize:(NSNotification *)notification;

@end
