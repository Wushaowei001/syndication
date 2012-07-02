//
//  CLStringHelper.h
//  Syndication
//
//  Created by Calvin Lough on 6/23/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

@interface CLStringHelper : NSObject {

}

+ (NSString *)stringFromData:(NSData *)data withPossibleEncoding:(NSStringEncoding)stringEncoding;

@end
