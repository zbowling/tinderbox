//
//  TBSocketRoute.m
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBSocketRoute.h"
#import "TBSocketRequest.h"
#import "TBSocketConnection.h"
#import "TBSocketRequestHandler.h"

/********************************************************************************************************************/

@interface TBSocketRegexRoute : TBSocketRoute 

- (id)initWithRegexString:(NSString *)regexString requestHandlerClass:(Class)handler;
- (id)initWithRegexString:(NSString *)regexString requestHandler:(id<TBSocketRequestHandler> )handler;

- (id)initWithRegularExpression:(NSRegularExpression *)regex requestHandlerClass:(Class)handler;
- (id)initWithRegularExpression:(NSRegularExpression *)regex requestHandler:(id<TBSocketRequestHandler> )handler;

@end

/********************************************************************************************************************/

@interface TBSocketPathRoute : TBSocketRoute 

- (id)initWithPathPrefixString:(NSString *)pathString requestHandlerClass:(Class)handler;
- (id)initWithPathPrefixString:(NSString *)pathString requestHandler:(id<TBSocketRequestHandler> )handler;

@end


/********************************************************************************************************************/

@implementation TBSocketRoute {
    id<TBSocketRequestHandler> _requestHandler;
    Class<TBSocketRequestHandler,NSObject> _requestHandlerClass;
}

+ (id)routeWithRegexString:(NSString *)regexString requestHandlerClass:(Class)handler {
    return [[TBSocketRegexRoute alloc] initWithRegexString:regexString requestHandlerClass:handler];
}

+ (id)routeWithRegexString:(NSString *)regexString requestHandler:(id<TBSocketRequestHandler> )handler {
    return [[TBSocketRegexRoute alloc] initWithRegexString:regexString requestHandler:handler];
}

+ (id)routeWithRegularExpression:(NSRegularExpression *)regex requestHandlerClass:(Class)handler {
    return [[TBSocketRegexRoute alloc] initWithRegularExpression:regex requestHandlerClass:handler];
}

+ (id)routeWithRegularExpression:(NSRegularExpression *)regex requestHandler:(id<TBSocketRequestHandler> )handler {
    return [[TBSocketRegexRoute alloc] initWithRegularExpression:regex requestHandler:handler];
}

+ (id)routeWithPathPrefixString:(NSString *)path requestHandlerClass:(Class)handler {
    return [[TBSocketPathRoute alloc] initWithPathPrefixString:path requestHandlerClass:handler];
}

+ (id)routeWithPathPrefixString:(NSString *)path requestHandler:(id<TBSocketRequestHandler> )handler {
    return [[TBSocketPathRoute alloc] initWithPathPrefixString:path requestHandler:handler];
}

- (id)initWithHandlerClass:(Class)requestHandlerClass {
    self = [super init];
    if (self) {
        _requestHandlerClass = requestHandlerClass;
    }
    return self;
}

- (id)initWithHandler:(id<TBSocketRequestHandler>)requestHandler {
    self = [super init];
    if (self) {
        _requestHandler = requestHandler;
    }
    return self;
}

- (id<TBSocketRequestHandler>)requestHandler {
    if (_requestHandler) {
        return _requestHandler;
    }
    else {
        return [[(Class)_requestHandlerClass alloc] init];
    }
}


- (BOOL)canHandleRequest:(TBSocketRequest *)request {
    SEL canHandleSel = @selector(canHandleRequest:);
    if (_requestHandlerClass) {
        if ([(Class)_requestHandlerClass respondsToSelector:canHandleSel])
        {
            return [_requestHandlerClass canHandleRequest:request];
        }
    }
    
    id<TBSocketRequestHandler> requestHandler = self.requestHandler;
    
    if ([requestHandler respondsToSelector:canHandleSel]) {
        return [requestHandler canHandleRequest:request];
    }
    else if ([[requestHandler class] respondsToSelector:canHandleSel]) {
        return [[requestHandler class] canHandleRequest:request];
    }
    
    return NO;
}

- (void)handleRequest:(TBSocketRequest *)request {
    [self.requestHandler handleRequest:request];
}

@end

/********************************************************************************************************************/

@implementation TBSocketRegexRoute {
    NSRegularExpression *_routeRegularExpression;
}

- (id)initWithRegexString:(NSString *)regexString requestHandlerClass:(Class)handler {
    NSRegularExpressionOptions options = NSRegularExpressionAllowCommentsAndWhitespace;
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:options error:&error];
    if (!regex) {
        NSLog(@"unable to parse route regular expression (\"%@\"). returned error %@",regexString, error);
        return nil;
    }
    return [self initWithRegularExpression:regex requestHandlerClass:handler];
}


- (id)initWithRegexString:(NSString *)regexString requestHandler:(id<TBSocketRequestHandler>)handler {
    NSRegularExpressionOptions options = NSRegularExpressionAllowCommentsAndWhitespace;
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:options error:&error];
    if (!regex) {
        NSLog(@"unable to parse route regular expression (\"%@\"). returned error %@",regexString, error);
        return nil;
    }
    return [self initWithRegularExpression:regex requestHandler:handler];
}

- (id)initWithRegularExpression:(NSRegularExpression *)regex requestHandlerClass:(__unsafe_unretained Class)handler
{
    self = [super initWithHandlerClass:handler];
    if (self) {
        _routeRegularExpression = regex;
    }
    return self;
}

- (id)initWithRegularExpression:(NSRegularExpression *)regex requestHandler:(id<TBSocketRequestHandler> )handler {
    NSParameterAssert(regex);
    self = [super initWithHandler:handler];
    if (self) {
        _routeRegularExpression = regex;
    }
    return self;
}

- (BOOL)canHandleRequest:(TBSocketRequest *)request {
    if (![super canHandleRequest:request]){
        return NO;
    }
    
    NSString *path = [[request URL] path];
    if (!path) {
        return NO;
    }
    
    if ([_routeRegularExpression numberOfMatchesInString:path options:0 range:NSMakeRange(0, [path length])] > 0){
        return YES;
    };
    
    return NO;
}

@end

/********************************************************************************************************************/

@implementation TBSocketPathRoute {
    NSString *_pathPrefix;
}


- (id)initWithPathPrefixString:(NSString *)pathPrefix requestHandlerClass:(Class)handler {
    self = [super initWithHandlerClass:handler];
    if (self) {
        _pathPrefix = pathPrefix;
    }
    return self;
}

- (id)initWithPathPrefixString:(NSString *)pathPrefix requestHandler:(id<TBSocketRequestHandler>)handler {
    self = [super initWithHandler:handler];
    if (self) {
        _pathPrefix = pathPrefix;
    }
    return self;
}

- (BOOL)canHandleRequest:(TBSocketRequest *)request {
    if (![super canHandleRequest:request]){
        return NO;
    }
    
    NSString *path = [[request URL] path];
    if (!path) {
        return NO;
    }
    
    if ([path hasPrefix:_pathPrefix]) {
        return YES;
    }
    
    return NO;
}

@end

