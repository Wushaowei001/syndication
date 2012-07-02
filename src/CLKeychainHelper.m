//
//  CLKeychainHelper.m
//  Syndication
//
//  Created by Calvin Lough on 4/14/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLKeychainHelper.h"

#define SERVICE_NAME "Syndication"

@implementation CLKeychainHelper

+ (BOOL)setPassword:(NSString *)passwordStr forAccount:(NSString *)accountStr {
	
	if (passwordStr == nil) {
		passwordStr = @"";
	}
	
	if (accountStr == nil) {
		accountStr = @"";
	}
	
	void *service = SERVICE_NAME;
	UInt32 serviceLen = (UInt32)strlen(service);
	void *account = (void *)[accountStr UTF8String];
	UInt32 accountLen = (UInt32)strlen(account);
	void *password = (void *)[passwordStr UTF8String];
	UInt32 passwordLen = (UInt32)strlen(password);
	
	char *passwordData = nil;
	SecKeychainItemRef itemRef = nil;
	UInt32 passwordDataLen = 0;
	
	// if we already have a saved password for this account, just change it
	OSStatus status = SecKeychainFindGenericPassword(NULL, serviceLen, service, accountLen, account, &passwordDataLen, (void **)&passwordData, &itemRef);
	OSStatus status2;
	
	if (status == noErr) {
		SecKeychainItemFreeContent(NULL, passwordData);
		
		status2 = SecKeychainItemModifyAttributesAndData(itemRef, NULL, passwordLen, password);
	} else {
		status2 = SecKeychainAddGenericPassword(NULL, serviceLen, service, accountLen, account, passwordLen, password, NULL);
	}
	
	if (itemRef) {
		CFRelease(itemRef);
	}
	
	return (status2 == noErr);
}

+ (NSString *)getPasswordForAccount:(NSString *)accountStr {
	
	if (accountStr == nil) {
		return nil;
	}
	
	NSString *password = nil;
	
	void *service = SERVICE_NAME;
	UInt32 serviceLen = (UInt32)strlen(service);
	void *account = (void *)[accountStr UTF8String];
	UInt32 accountLen = (UInt32)strlen(account);
	
	char *passwordData = nil;
	SecKeychainItemRef itemRef = nil;
	UInt32 passwordDataLen = 0;
	
	OSStatus status = SecKeychainFindGenericPassword(NULL, serviceLen, service, accountLen, account, &passwordDataLen, (void **)&passwordData, &itemRef);
	
	if (status == noErr) {
		passwordData[passwordDataLen] = '\0';
		password = [NSString stringWithUTF8String:passwordData];
		
		SecKeychainItemFreeContent(NULL, passwordData);
	}
	
	if (itemRef) {
		CFRelease(itemRef);
	}
	
	return password;
}

@end
