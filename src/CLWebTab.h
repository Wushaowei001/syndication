//
//  CLWebTab.h
//  Syndication
//
//  Created by Calvin Lough on 2/16/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@class CLWebTabToolbarView;
@class CLWebView;

@interface CLWebTab : NSObject {
	NSView *view;
	CLWebTabToolbarView *toolbarView;
	CLWebView *webView;
	NSString *urlString;
	BOOL titleReceived;
}

@property (assign, nonatomic) IBOutlet NSView *view;
@property (assign, nonatomic) IBOutlet CLWebTabToolbarView *toolbarView;
@property (assign, nonatomic) IBOutlet CLWebView *webView;
@property (retain, nonatomic) NSString *urlString;
@property (assign, nonatomic) BOOL titleReceived;

- (IBAction)backForward:(id)sender;
- (IBAction)reload:(id)sender;
- (IBAction)textField:(id)sender;
- (void)updateBackForwardEnabled;

@end
