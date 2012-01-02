//
//  TBSocketRoute.h
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TBSocketRequestHandler.h"
@class TBSocketRequest, TBSocketConnection;

@interface TBSocketRoute : NSObject<TBSocketRequestHandler>

+ (id)routeWithRegexString:(NSString *)regexString requestHandlerClass:(Class)handler;
+ (id)routeWithRegexString:(NSString *)regexString requestHandler:(id<TBSocketRequestHandler>)handler;

+ (id)routeWithRegularExpression:(NSRegularExpression *)regex requestHandlerClass:(Class)handler;
+ (id)routeWithRegularExpression:(NSRegularExpression *)regex requestHandler:(id<TBSocketRequestHandler>)handler;

+ (id)routeWithPathPrefixString:(NSString *)path requestHandlerClass:(Class)handler;
+ (id)routeWithPathPrefixString:(NSString *)path requestHandler:(id<TBSocketRequestHandler>)handler;

@property (readonly, strong) id<TBSocketRequestHandler> requestHandler;

@end
