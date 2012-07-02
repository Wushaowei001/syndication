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

- (void)queueNonGoogleSyncRequest;
- (void)queueGoogleSyncRequest;
- (void)queueGoogleStarredSyncRequest;
- (void)numberOfTabsDidChange;
- (void)tabSelectionDidChange;
- (void)timelineSelectionDidChange;
- (void)classicViewSelectionDidChange;
- (void)webTabDidFinishLoad;
- (void)sourceListDidChange;
- (void)sourceListDidRenameItem:(CLSourceListItem *)item propagateChangesToGoogle:(BOOL)propagate;
- (CLWindowController *)newWindow;
- (void)openNewWindowForSubscription:(CLSourceListItem *)subscription;
- (void)openNewWindowForUrlRequest:(NSURLRequest *)request;
- (void)changeNewItemsBadgeValueBy:(NSInteger)value;
- (void)refreshTabsForAncestorsOf:(CLSourceListItem *)item;
- (void)refreshTabsFor:(CLSourceListItem *)item;
- (void)restoreSourceListSelections;
- (CLSourceListFeed *)feedForDbId:(NSInteger)dbId;
- (CLSourceListFeed *)addSubscriptionForUrlString:(NSString *)url withTitle:(NSString *)feedTitle toFolder:(CLSourceListFolder *)folder isFromGoogle:(BOOL)isFromGoogle propagateChangesToGoogle:(BOOL)propagate refreshImmediately:(BOOL)shouldRefresh;
- (void)sortSourceList;
- (void)deleteSourceListItem:(CLSourceListItem *)item propagateChangesToGoogle:(BOOL)propagate;
- (void)markAllAsReadForSourceListItem:(CLSourceListItem *)item orNewItems:(BOOL)newItems orStarredItems:(BOOL)starredItems orPostsOlderThan:(NSNumber *)timestamp;
- (void)markPostWithDbIdAsRead:(NSInteger)dbId propagateChangesToGoogle:(BOOL)propagate;
- (CLSourceListFolder *)addFolderWithTitle:(NSString *)folderTitle toFolder:(CLSourceListFolder *)folder forWindow:(CLWindowController *)winController;
- (void)refreshSourceListItem:(CLSourceListItem *)item onlyGoogle:(BOOL)onlyGoogle;
- (void)moveItem:(CLSourceListItem *)item toFolder:(CLSourceListFolder *)folder propagateChangesToGoogle:(BOOL)propagate;
- (NSString *)preferenceHeadlineFontName;
- (CGFloat)preferenceHeadlineFontSize;
- (NSString *)preferenceBodyFontName;
- (CGFloat)preferenceBodyFontSize;

@end
