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

- (void)handleRequest:(TBSocketRequest *)request; 

@optional
- (BOOL)canHandleRequest:(TBSocketRequest *)request;
+ (BOOL)canHandleRequest:(TBSocketRequest *)request;


@end
