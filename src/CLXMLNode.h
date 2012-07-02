//
//  CLXMLNode.h
//  Syndication
//
//  Created by Calvin Lough on 3/4/11.
//  Copyright 2011 Calvin Lough. All rights reserved.
//

typedef enum {CLXMLElementNode, CLXMLTextNode} CLXMLNodeType;

@interface CLXMLNode : NSObject {
	NSString *name;
	NSString *nameSpace;
	NSString *content;
	NSMutableDictionary *attributes;
	NSMutableArray *children;
	CLXMLNodeType type;
}

@property (retain, nonatomic) NSString *name;
@property (retain, nonatomic) NSString *nameSpace;
@property (retain, nonatomic) NSString *content;
@property (retain, nonatomic) NSMutableDictionary *attributes;
@property (retain, nonatomic) NSMutableArray *children;
@property (assign, nonatomic) CLXMLNodeType type;

+ (CLXMLNode *)xmlNode;

- (NSString *)combinedTextValue;

@end
