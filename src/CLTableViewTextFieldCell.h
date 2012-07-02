//
//  CLTableViewTextFieldCell.h
//  Syndication
//
//  Created by Calvin Lough on 5/4/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLTableViewTextFieldCellDelegate.h"

@class CLTableView;

@interface CLTableViewTextFieldCell : NSTextFieldCell {
	id <CLTableViewTextFieldCellDelegate> delegate;
	NSInteger rowIndex;
	CLTableView *tableViewReference;
}

@property (assign, nonatomic) id <CLTableViewTextFieldCellDelegate> delegate;
@property (assign, nonatomic) NSInteger rowIndex;
@property (assign, nonatomic) CLTableView *tableViewReference;

@end
