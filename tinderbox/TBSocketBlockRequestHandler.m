//
//  TBSocketRestRequestHandler.m
//  tinderbox
//
//  Created by Zac Bowling on 1/1/12.
//  Copyright (c) 2012 Zac Bowling. All rights reserved.
//

#import "TBSocketBlockRequestHandler.h"
#import "TBSocketRequest.h"
#import "TBSocketConnection.h"
#import "TBSocketResponse.h"


@implementation TBSocketBlockRequestHandler

@synthesize requestHandlerBlock=_requestHandlerBlock;

+ (id)handlerWithBlock:(TBSocketBlockRequestHandlerBlock)block {
    return [[self alloc] initWithBlock:block];
}

- (id)initWithBlock:(TBSocketBlockRequestHandlerBlock)block {
    self = [super init];
    if (self) {
        _requestHandlerBlock = [block copy];
    }
    return self;
}

- (BOOL)canHandleRequest:(TBSocketRequest *)request {
    return YES;
}

- (void)handleRequest:(TBSocketRequest *)request {
    _requestHandlerBlock(self, request);
}

@end
