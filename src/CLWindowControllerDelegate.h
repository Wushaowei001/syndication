//
//  CLWindowControllerDelegate.h
//  Syndication
//
//  Created by Calvin Lough on 2/18/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@class CLSourceListFeed;
@class CLSourceListFolder;
@class CLSourceListItem;
@class CLWindowController;

@protocol CLWindowControllerDelegate <NSObject>

- (void)queueAllFeedsSyncRequest;
- (void)numberOfTabsDidChange;
- (void)tabSelectionDidChange;
- (void)timelineSelectionDidChange;
- (void)classicViewSelectionDidChange;
- (void)webTabDidFinishLoad;
- (void)sourceListDidChange;
- (void)sourceListDidRenameItem:(CLSourceListItem *)item;
- (CLWindowController *)newWindow;
- (void)openNewWindowForSubscription:(CLSourceListItem *)subscription;
- (void)openNewWindowForUrlRequest:(NSURLRequest *)request;
- (void)changeNewItemsBadgeValueBy:(NSInteger)value;
- (void)clearNewItemsBadgeValue;
- (void)refreshTabsForAncestorsOf:(CLSourceListItem *)item;
- (void)refreshTabsFor:(CLSourceListItem *)item;
- (void)restoreSourceListSelections;
- (CLSourceListFeed *)feedForDbId:(NSInteger)dbId;
- (CLSourceListFeed *)addSubscriptionForUrlString:(NSString *)url withTitle:(NSString *)feedTitle toFolder:(CLSourceListFolder *)folder refreshImmediately:(BOOL)shouldRefresh;
- (void)sortSourceList;
- (void)deleteSourceListItem:(CLSourceListItem *)item;
- (void)markAllAsReadForSourceListItem:(CLSourceListItem *)item orNewItems:(BOOL)newItems orStarredItems:(BOOL)starredItems orPostsOlderThan:(NSNumber *)timestamp;
- (void)markPostWithDbIdAsRead:(NSInteger)dbId;
- (CLSourceListFolder *)addFolderWithTitle:(NSString *)folderTitle toFolder:(CLSourceListFolder *)folder forWindow:(CLWindowController *)winController;
- (void)refreshSourceListItem:(CLSourceListItem *)item;
- (void)moveItem:(CLSourceListItem *)item toFolder:(CLSourceListFolder *)folder;
- (NSString *)preferenceHeadlineFontName;
- (CGFloat)preferenceHeadlineFontSize;
- (NSString *)preferenceBodyFontName;
- (CGFloat)preferenceBodyFontSize;

@end
