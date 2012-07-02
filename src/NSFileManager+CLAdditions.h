//
//  NSFileManager+CLAdditions.h
//  Syndication
//
//  Created by Calvin Lough on 01/08/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@interface NSFileManager (CLAdditions)

- (NSString *)ayApplicationSupportDirectory;
- (NSString *)aySyndicationSupportDirectory;
- (void)ayCopyLiteDirectoryIfItExistsAndRegularDirectoryDoesnt;

@end
