//
//  CLConstants.h
//  Syndication
//
//  Created by Calvin Lough on 3/9/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#ifndef NDEBUG
#define CLLog(format, ...) NSLog([@"%s:%d " stringByAppendingString:format], __FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define CLLog(...)
#endif

#define TIME_INTERVAL_MINUTE 60
#define TIME_INTERVAL_HOUR (TIME_INTERVAL_MINUTE * 60)
#define TIME_INTERVAL_DAY (TIME_INTERVAL_HOUR * 24)
#define TIME_INTERVAL_WEEK (TIME_INTERVAL_DAY * 7)
#define TIME_INTERVAL_MONTH (TIME_INTERVAL_DAY * 30) // approximate, but don't change because preferences window depends on this exact value
#define TIME_INTERVAL_YEAR (TIME_INTERVAL_DAY * 365)

#define TAB_CLOSE_WIDTH 12
#define TAB_CLOSE_HEIGHT 12
#define TAB_CLOSE_X_INDENT 5
#define TAB_CLOSE_Y_INDENT 5
#define TABVIEW_ADD_BUTTON_WIDTH 28

#define TIMELINE_FIRST_ITEM_MARGIN_TOP 1
#define TIMELINE_LAST_ITEM_MARGIN_BOTTOM 10
#define TIMELINE_SCROLL_BUFFER 50
#define TIMELINE_ITEM_BUFFER 15
#define TIMELINE_ITEM_DEFAULT_HEIGHT 70
#define TIMELINE_ITEM_REFRESH_COUNT 4
#define TIMELINE_UNLOAD_MULTIPLIER 4

#define SOURCE_LIST_ICON_WIDTH 16
#define SOURCE_LIST_ICON_HEIGHT 16
#define SOURCE_LIST_ICON_PADDING_LEFT 5
#define SOURCE_LIST_ICON_PADDING_RIGHT 4
#define SOURCE_LIST_BADGE_PADDING 6

#define MISCELLANEOUS_GOOGLE_EMAIL_KEY @"MiscellaneousGoogleEmail"
#define MISCELLANEOUS_ADD_TO_GOOGLE_KEY @"MiscellaneousAddToGoogle"
#define MISCELLANEOUS_LAST_FEED_SYNC_KEY @"MiscellaneousLastFeedSync"
#define MISCELLANEOUS_DATABASE_VERSION @"MiscellaneousDatabaseVersion"
#define MISCELLANEOUS_VIEW_MODE @"MiscellaneousViewMode"
#define MISCELLANEOUS_FIRST_LAUNCH @"MiscellaneousFirstLaunch"
#define MISCELLANEOUS_HEADLINE_FONT_NAME @"MiscellaneousHeadlineFontName"
#define MISCELLANEOUS_HEADLINE_FONT_SIZE @"MiscellaneousHeadlineFontSize"
#define MISCELLANEOUS_BODY_FONT_NAME @"MiscellaneousBodyFontName"
#define MISCELLANEOUS_BODY_FONT_SIZE @"MiscellaneousBodyFontSize"
#define MISCELLANEOUS_CLASSIC_VIEW_DIVIDER_POSITION @"MiscellaneousClassicViewDividerPosition"

typedef enum {CLAddFeedType, CLAddStarType, CLAddToFolderType, CLDeleteFeedType, CLFeedTitleType, CLMarkReadType, CLRemoveFromFolderType, CLRemoveStarType} CLDatabaseGoogleOperationType;

enum {CLEscapeCharacter = 27, CLSpaceCharacter = 32};

#define GOOGLE_REQUEST_PAUSE 0.1
#define GOOGLE_FETCH_SIZE 200
#define OFFLINE_RETRY_PAUSE 5.0
#define FEED_REQUEST_DELAY 5.0

#define URL_REQUEST_TIMEOUT TIME_INTERVAL_MINUTE

#define PROCESS_NEW_POSTS_BATCH_SIZE 50
#define PROCESS_NEW_POSTS_DELAY 0.15
#define PROCESS_NEW_POSTS_SKIPPED_AT_TOP -1
#define PROCESS_NEW_POSTS_SKIPPED_AT_BOTTOM -2

#define VIEW_SWITCH_BUFFER 60

#define CSS_FORMAT_STRING @"<style type=\"text/css\">body {margin: 0; color: rgb(30, 30, 30)} a, a:link, a:active, a:visited {color: rgb(34, 98, 205); text-decoration: none} a:hover {text-decoration: underline} p {margin: 0 0 1em} p:last-child {margin-bottom: 0} table {margin: 0 0 1em} th {font-weight: bold} #postHeadline, #postHeadline a {text-decoration: none; color: rgb(30, 30, 30)} #postContent {padding-bottom: 17px} .postMeta {margin: 4px 0 5px; color: rgb(140, 140, 140)} blockquote {margin: 0.9em 30px} p+blockquote {margin-top: -0.4em} h1, h2, h3, h4, h5, h6 {font-weight: bold !important; margin: 1.35em 0 0.35em; line-height: 1.25em} h1 {font-size: 1.1em} h2 {font-size: 1.05em} h3, h4, h5, h6 {font-size: 1em} #postEnclosureTitle {font-weight: bold; font-size: 0.85em; color: rgb(120, 120, 120)} .fakeHR {margin-bottom: 14px; height: 0px; border-bottom: 1px solid rgb(220, 220, 220)}</style>"
#define NO_POSTS_HTML_STRING @"<html><head><style type=\"text/css\">body {margin: 0; font: 10pt 'Helvetica Neue', Helvetica, sans-serif} .errorBox {margin: 41px; padding: 10px 30px; border: 1px solid rgb(200, 200, 200); -webkit-border-radius: 11px} .errorBox h1 {font-size: 18px; font-weight: 500; color: rgb(110, 110, 110)}</style></head><body><div class=\"errorBox\"><h1>%@</h1></div></body></html>"

typedef enum {CLTableViewImageStyle, CLTableViewNoImageStyle} CLTableViewSelectionStyle;

#define TABLE_VIEW_SELECTION_STYLE CLTableViewNoImageStyle
