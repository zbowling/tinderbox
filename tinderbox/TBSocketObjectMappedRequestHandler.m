//
//  TBSocketObjectMappedRequestHandler.m
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBSocketObjectMappedRequestHandler.h"
#import "TBSocketRequest.h"
#import "NSDictionary+TB.h"

@implementation TBSocketObjectMappedRequestHandler {
    NSObject *_targetObject;
}

-(void)setTargetObject:(NSObject *)targetObject {
    if (targetObject != _targetObject) {
        if (targetObject == self) {
            _targetObject = nil;
        }
        else {
            _targetObject = targetObject;
        }
    }
}

- (NSObject *)targetObject {
    if (_targetObject)
        return _targetObject;
    else
        return self;
}

- (BOOL)canHandleRequest:(TBSocketRequest *)request {
    NSString *lastPathComponent = [[[request URL] path] lastPathComponent];
    if (!lastPathComponent) {
        return NO;
    }
    
    if ([_targetObject respondsToSelector:NSSelectorFromString(lastPathComponent)]){
        return YES;
    }
    
    NSString *selectorString = [NSString stringWithFormat:@"%@:",lastPathComponent];
    if ([_targetObject respondsToSelector:NSSelectorFromString(selectorString)]){
        return YES;
    }
    
    return NO;
}

- (void)handleRequest:(TBSocketRequest *)request {
    NSString *lastPathComponent = [[[request URL] path] lastPathComponent];
    
    SEL sel = NSSelectorFromString(lastPathComponent);
    
    if (![_targetObject respondsToSelector:sel]) {
        sel = NSSelectorFromString([NSString stringWithFormat:@"%@:",lastPathComponent]);
    }

    NSMethodSignature *signature = [_targetObject methodSignatureForSelector:sel];
    
    if (signature){
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:_targetObject];
        [invocation setSelector:sel];
        
        if ([signature numberOfArguments] == 3) {
            if (strcmp([signature getArgumentTypeAtIndex:3],"@") == 0) {
                NSDictionary *queryParams = [NSDictionary dictionaryWithFormEncodedString:[[request URL] query]];
                [invocation setArgument:&queryParams atIndex:3];
            }

        }
        
        
        if (strcmp([signature methodReturnType],"@")==0){
            
        }
        else {
            return;
        }
    }
    
}




@end
