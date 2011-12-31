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

@property (readonly) NSArray *requestRoutes;

- (void)addRequestRoute:(TBSocketRoute *)requestRoute;
- (void)insertRequestRoute:(TBSocketRoute *)requestRoute atIndex:(NSUInteger)index;
- (void)removeRequestRoute:(TBSocketRoute *)requestRoute;
- (void)removeAllRequestRoutes;



@end
