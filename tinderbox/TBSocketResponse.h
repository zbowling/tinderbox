//
//  TBSocketResponse.h
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TBSocketResponse : NSObject


-(id)initWithStatusCode:(NSInteger)statusCode HTTPVersion:(NSString *)HTTPVersion headerFields:(NSDictionary *)headerFields responseBodyStream:(NSInputStream *)responseBodyStream;
-(id)initWithStatusCode:(NSInteger)statusCode HTTPVersion:(NSString *)HTTPVersion headerFields:(NSDictionary *)headerFields body:(NSData *)body;
-(id)initWithStatusCode:(NSInteger)statusCode HTTPVersion:(NSString *)HTTPVersion headerFields:(NSDictionary *)headerFields;

@property (readonly,nonatomic) CFHTTPMessageRef HTTPMessage;

@property (readonly,nonatomic) NSInputStream *responseBodyStream;

@end
