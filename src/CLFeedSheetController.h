//
//  CLFeedSheetController.h
//  Syndication
//
//  Created by Calvin Lough on 01/10/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@interface CLFeedSheetController : NSWindowController {
	NSWindow *mainWindow;
	NSPanel *addFeedSheet;
}

@property (assign, nonatomic) IBOutlet NSWindow *mainWindow;
@property (assign, nonatomic) IBOutlet NSPanel *addFeedSheet;

- (IBAction)showSheet:(id)sender;
- (IBAction)hideSheet:(id)sender;
- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

@end
