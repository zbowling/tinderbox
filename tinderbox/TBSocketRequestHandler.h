//
//  TBSocketRequestHandler.h
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TBSocketRequest;
@class TBSocketConnection;

@protocol TBSocketRequestHandler <NSObject>

- (void)processRequest:(TBSocketRequest *)request withSocketConnection:(TBSocketConnection *)connection; 

@end
