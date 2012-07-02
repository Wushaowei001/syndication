//
//  CLSourceListFolder.h
//  Syndication
//
//  Created by Calvin Lough on 2/20/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLSourceListItem.h"

@class CLSourceListFolder;

@interface CLSourceListFolder : CLSourceListItem {
	NSInteger dbId;
	NSString *path;
	CLSourceListFolder *parentFolderReference;
}

@property (assign, nonatomic) NSInteger dbId;
@property (copy, nonatomic) NSString *path;
@property (assign, nonatomic) CLSourceListFolder *parentFolderReference;

@end
