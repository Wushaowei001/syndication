//
//  CLUrlFetcher.h
//  Syndication
//
//  Created by Calvin Lough on 4/7/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@interface CLUrlFetcher : NSObject {

}

+ (NSData *)fetchUrlString:(NSString *)urlString postData:(NSData *)postData returnNilOnFailure:(BOOL)nilOnFail urlResponse:(NSURLResponse **)urlResponse;
+ (NSURLConnection *)fetchUrlString:(NSString *)urlString delegate:(id)delegate;
+ (BOOL)isSuccessStatusCode:(NSInteger)code;

@end
