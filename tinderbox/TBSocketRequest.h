//
//  TBNodeCallbackRequest.h
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TBSocketConnection;

@interface TBSocketRequest : NSObject

- (id)initWithHTTPMessage:(CFHTTPMessageRef)requestRef connection:(TBSocketConnection *)connection;

@property (nonatomic, readonly, strong) TBSocketConnection *connection; 
@property (nonatomic, readonly) CFHTTPMessageRef requestHTTPMessage;
@property (nonatomic, readonly) NSString *HTTPMethod;
@property (nonatomic, readonly) NSString *HTTPVersion;
@property (nonatomic, readonly) NSDictionary *allHTTPHeaderFields;
@property (nonatomic, readonly) NSData *HTTPBody;
@property (nonatomic, readonly) NSURL *URL;

- (NSDictionary *)URLQueryParams;

@end
