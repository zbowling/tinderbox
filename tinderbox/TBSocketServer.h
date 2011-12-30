//
//  TBNodeCallbackServer.h
//  tinderbox
//
//  Created by Zac Bowling on 12/28/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TBSocketConnection;

@interface TBSocketServer : NSObject<NSStreamDelegate>

-(id)initWithSocketPath:(NSString *)path;

-(void)invalidateConnection:(TBSocketConnection *)connection;

@end
