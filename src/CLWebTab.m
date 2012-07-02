//
//  CLWebTab.m
//  Syndication
//
//  Created by Calvin Lough on 2/16/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLWebTab.h"
#import "CLWebTabToolbarView.h"
#import "CLWebView.h"
#import "NSString+CLAdditions.h"

@implementation CLWebTab

@synthesize view;
@synthesize toolbarView;
@synthesize webView;
@synthesize urlString;
@synthesize titleReceived;

- (id)init {
    self = [super init];
	
	if (self != nil) {
        if (![NSBundle loadNibNamed:@"CLWebTab" owner:self]) {
            [self release];
            self = nil;
        }
    }
	
	if (self != nil) {
		[self setUrlString:[NSString string]];
		[self setTitleReceived:NO];
	}
	
    return self;
}

- (void)dealloc {
	[webView stopLoading:self];
	[webView setTabViewItemReference:nil];
	[webView setFrameLoadDelegate:nil];
	[webView setPolicyDelegate:nil];
	[webView setUIDelegate:nil];
	
	[view release]; // send a release message to root object of the nib file
	[urlString release];
	
	[super dealloc];
}

- (IBAction)backForward:(id)sender {
	NSInteger clickedSegment = [sender selectedSegment];
	NSInteger clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	
	if (clickedSegmentTag == 0) {
		[webView goBack];
	} else if (clickedSegmentTag == 1) {
		[webView goForward];
	}
}

- (IBAction)reload:(id)sender {
	if (urlString != nil && [urlString length] > 0) {
		NSURL *url = [NSURL URLWithString:urlString];
		NSURLRequest *request = [NSURLRequest requestWithURL:url];
		[[webView mainFrame] loadRequest:request];
	}
}

- (IBAction)textField:(id)sender {
	NSString *stringToLoad = [[sender stringValue] ayTrimmedString];
	
	if ([[stringToLoad substringToIndex:7] isEqual:@"feed://"]) {
		stringToLoad = [NSString stringWithFormat:@"http://%@", [stringToLoad substringFromIndex:7]];
	}
	
	NSURL *url = [NSURL URLWithString:stringToLoad];
	
	// add http:// to the beginning if necessary
	if ([url scheme] == nil) {
		NSString *stringTest = [NSString stringWithFormat:@"http://%@", stringToLoad];
		NSURL *urlTest = [NSURL URLWithString:stringTest];
		
		if (urlTest != nil && [[urlTest scheme] isEqual:@"http"]) {
			url = urlTest;
		}
	}
	
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	
	[[webView mainFrame] loadRequest:request];
	[[view window] makeFirstResponder:webView];
}

- (void)updateBackForwardEnabled {
	NSSegmentedControl *backForward = [toolbarView backForward];
	
	[backForward setEnabled:NO forSegment:0];
	[backForward setEnabled:NO forSegment:1];
	
	if ([webView canGoBack]) {
		[backForward setEnabled:YES forSegment:0];
	}
	
	if ([webView canGoForward]) {
		[backForward setEnabled:YES forSegment:1];
	}
}

@end
