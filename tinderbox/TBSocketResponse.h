//
//  TBSocketResponse.h
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TBSocketResponse : NSObject

+(id)serverErrorResponseWithString:(NSString *)errorString;
+(id)serverErrorResponseWithError:(NSError *)error;

+(id)redirectResponseWithLocation:(NSString *)location;

+(id)responseWithStatusCode:(NSInteger)statusCode;
+(id)responseWithStatusCode:(NSInteger)statusCode headerFields:(NSDictionary *)headerFields body:(NSData *)body;
+(id)responseWithStatusCode:(NSInteger)statusCode contentType:(NSString *)contentType body:(NSData *)body;

-(id)initWithStatusCode:(NSInteger)statusCode HTTPVersion:(NSString *)HTTPVersion headerFields:(NSDictionary *)headerFields responseBodyStream:(NSInputStream *)responseBodyStream;
-(id)initWithStatusCode:(NSInteger)statusCode HTTPVersion:(NSString *)HTTPVersion headerFields:(NSDictionary *)headerFields body:(NSData *)body;
-(id)initWithStatusCode:(NSInteger)statusCode HTTPVersion:(NSString *)HTTPVersion headerFields:(NSDictionary *)headerFields;

@property (readonly, nonatomic) CFHTTPMessageRef HTTPMessage;

@property (readonly, nonatomic) NSInputStream *responseBodyStream;

@property (nonatomic, readonly) NSString *HTTPMethod;
@property (nonatomic, readonly) NSString *HTTPVersion;
@property (nonatomic, readonly) NSDictionary *allHTTPHeaderFields;
@property (nonatomic, readonly) NSData *HTTPBody;
@property (nonatomic, readonly) NSURL *URL;

@end
