//
//  TBSocketRestRequestHandler.h
//  tinderbox
//
//  Created by Zac Bowling on 1/1/12.
//  Copyright (c) 2012 Zac Bowling. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TBSocketRequestHandler.h"

@class TBSocketBlockRequestHandler;

typedef void(^TBSocketBlockRequestHandlerBlock)(TBSocketBlockRequestHandler *handler, TBSocketRequest *request);

@interface TBSocketBlockRequestHandler : NSObject<TBSocketRequestHandler>

+ (id)handlerWithBlock:(TBSocketBlockRequestHandlerBlock)block;

- (id)initWithBlock:(TBSocketBlockRequestHandlerBlock)block;

@property (copy,nonatomic) TBSocketBlockRequestHandlerBlock requestHandlerBlock;

@end
