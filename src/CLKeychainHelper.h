//
//  CLKeychainHelper.h
//  Syndication
//
//  Created by Calvin Lough on 4/14/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import <Security/Security.h>
#import <CoreFoundation/CoreFoundation.h>

@interface CLKeychainHelper : NSObject {

}

+ (BOOL)setPassword:(NSString *)passwordStr forAccount:(NSString *)accountStr;
+ (NSString *)getPasswordForAccount:(NSString *)accountStr;

@end
