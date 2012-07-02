//
//  CLTableViewTextFieldCellDelegate.h
//  Syndication
//
//  Created by Calvin Lough on 5/5/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@class CLPost;
@class CLTableViewTextFieldCell;

@protocol CLTableViewTextFieldCellDelegate <NSObject>

- (CLPost *)tableViewTextFieldCell:(CLTableViewTextFieldCell *)tableViewTextFieldCell postForRow:(NSInteger)rowIndex;

@end
