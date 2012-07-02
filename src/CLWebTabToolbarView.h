//
//  CLWebTabToolbarView.h
//  Syndication
//
//  Created by Calvin Lough on 5/14/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@interface CLWebTabToolbarView : NSView {
	NSSegmentedControl *backForward;
	NSTextField *textField;
}

@property (assign, nonatomic) IBOutlet NSSegmentedControl *backForward;
@property (assign, nonatomic) IBOutlet NSTextField *textField;

@end
