//
//  TBSocketConnection.h
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Foundation/Foundation.h>


@class TBSocketRequest, TBSocketServer, TBSocketResponse;

typedef BOOL (^TBRequestReceivedHandlerBlock)(TBSocketRequest *request);

@interface TBSocketConnection : NSObject <NSStreamDelegate>

- (id)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream socketServer:(TBSocketServer *)server;

- (BOOL)processIncomingBytes;
- (void)processOutgoingBytes;
- (void)performDefaultRequestHandling:(TBSocketRequest *)message;

- (BOOL)isValid;
- (void)invalidate;

- (TBSocketRequest *)nextRequest;

@property (copy,nonatomic) TBRequestReceivedHandlerBlock requestReceievedHandler;

//This will accept TBSocketResponse, NSData, or NSString. It also accepts NSDictionary and NSArray which it converts to JSON.
- (void)sendResponse:(id)response forRequest:(TBSocketRequest *)request;

@end
