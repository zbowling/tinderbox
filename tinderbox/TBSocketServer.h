//
//  TBNodeCallbackServer.h
//  tinderbox
//
//  Created by Zac Bowling on 12/28/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TBSocketRequestHandler;
@class TBSocketConnection;
@class TBSocketRoute;

@interface TBSocketServer : NSObject<NSStreamDelegate>

-(id)initWithSocketPath:(NSString *)path;

-(void)invalidateConnection:(TBSocketConnection *)connection;

@property (readonly) NSArray *requestHandlers;

- (void)addRequestHandler:(id<TBSocketRequestHandler>)requestHandler;
- (void)insertRequestHandler:(id<TBSocketRequestHandler>)requestHandler atIndex:(NSUInteger)index;
- (void)removeRequestHandler:(id<TBSocketRequestHandler>)requestHandler;
- (void)removeAllRequestHandlers;


- (BOOL)startServer:(NSError **)error;
- (BOOL)stopServer;


@end
