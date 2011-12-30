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

- (id)initWithRequest:(CFHTTPMessageRef)requestRef connection:(TBSocketConnection *)connnection;

@property (nonatomic, readonly) TBSocketConnection *connection;
@property (nonatomic, strong) NSInputStream *responseBodyStream;
@property (nonatomic, readonly) CFHTTPMessageRef request;
@property (nonatomic, readwrite) CFHTTPMessageRef response;

@end
