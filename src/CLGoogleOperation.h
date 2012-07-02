//
//  CLGoogleOperation.h
//  Syndication
//
//  Created by Calvin Lough on 3/31/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

#import "CLGoogleOperationDelegate.h"
#import "CLOperation.h"

@interface CLGoogleOperation : CLOperation {
	NSString *googleAuth;
	BOOL _isExecuting;
	BOOL _isFinished;
}

@property (copy) NSString *googleAuth;
@property (assign) BOOL _isExecuting;
@property (assign) BOOL _isFinished;

- (id <CLGoogleOperationDelegate>)delegate;
- (void)setDelegate:(id <CLGoogleOperationDelegate>)delegate;

- (BOOL)isConcurrent;
- (BOOL)isExecuting;
- (BOOL)isFinished;
- (void)completeOperation;
- (void)restartOperation;
- (BOOL)updateAuth;
- (BOOL)resetAuth;

- (NSData *)fetchUrlString:(NSString *)urlString postData:(NSData *)postData usingAuth:(NSString *)auth returnNilOnFailure:(BOOL)nilOnFail statusCode:(NSInteger *)statusCode;
- (NSDictionary *)doLoginWithEmail:(NSString *)email andPassword:(NSString *)password statusCode:(NSInteger *)statusCode;
- (NSData *)fetchFeedListUsingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode;
- (NSData *)fetchUnreadCountsUsingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode;
- (NSData *)fetch:(NSInteger)count itemsForUrlString:(NSString *)urlString since:(NSInteger)since usingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode;
- (NSData *)fetch:(NSInteger)count itemsForUrlString:(NSString *)urlString since:(NSInteger)since continuation:(NSString *)continuation usingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode;
- (NSData *)fetch:(NSInteger)count unreadItemsForUrlString:(NSString *)urlString since:(NSInteger)since usingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode;
- (NSData *)fetch:(NSInteger)count unreadItemsForUrlString:(NSString *)urlString since:(NSInteger)since continuation:(NSString *)continuation usingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode;
- (NSData *)fetch:(NSInteger)count starredItemsUsingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode;
- (NSData *)fetch:(NSInteger)count starredItemsUsingAuth:(NSString *)auth continuation:(NSString *)continuation statusCode:(NSInteger *)statusCode;
- (NSData *)fetchTokenUsingAuth:(NSString *)auth statusCode:(NSInteger *)statusCode;
- (NSData *)addToFolder:(NSString *)folder forUrlString:(NSString *)urlString token:(NSString *)token auth:(NSString *)auth statusCode:(NSInteger *)statusCode;
- (NSData *)removeFromFolder:(NSString *)folder forUrlString:(NSString *)urlString token:(NSString *)token auth:(NSString *)auth statusCode:(NSInteger *)statusCode;
- (NSData *)addTag:(NSString *)tag forUrlString:(NSString *)urlString item:(NSString *)item token:(NSString *)token auth:(NSString *)auth statusCode:(NSInteger *)statusCode;
- (NSData *)removeTag:(NSString *)tag forUrlString:(NSString *)urlString item:(NSString *)item token:(NSString *)token auth:(NSString *)auth statusCode:(NSInteger *)statusCode;
- (NSData *)addSubscriptionForUrlString:(NSString *)urlString token:(NSString *)token auth:(NSString *)auth statusCode:(NSInteger *)statusCode;
- (NSData *)deleteSubscriptionForUrlString:(NSString *)urlString token:(NSString *)token auth:(NSString *)auth statusCode:(NSInteger *)statusCode;
- (NSData *)updateTitle:(NSString *)title forUrlString:(NSString *)urlString token:(NSString *)token auth:(NSString *)auth statusCode:(NSInteger *)statusCode;

- (void)dispatchAuthDelegateMessage;
- (void)dispatchAuthErrorDelegateMessage:(NSDictionary *)authError;

@end
