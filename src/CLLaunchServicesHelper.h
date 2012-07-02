//
//  CLLaunchServicesHelper.h
//  Syndication
//
//  Created by Calvin Lough on 3/21/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@interface CLLaunchServicesHelper : NSObject {

}

+ (void)setDefaultHandlerForUrlScheme:(NSString *)scheme bundleId:(NSString *)bundleId;
+ (NSString *)defaultHandlerForUrlScheme:(NSString *)scheme;
+ (NSArray *)allHandlersForUrlScheme:(NSString *)scheme;
+ (NSString *)nameForBundleId:(NSString *)bundleId;
+ (NSImage *)iconForBundleId:(NSString *)bundleId;

@end
