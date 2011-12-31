//
//  TBSocketObjectMappedRequestHandler.m
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBSocketObjectMappedRequestHandler.h"
#import "TBSocketRequest.h"

@implementation TBSocketObjectMappedRequestHandler {
    id<NSObject> _targetObject;
}

-(void)setTargetObject:(id<NSObject>)targetObject {
    if (targetObject != _targetObject) {
        if (targetObject == self) {
            _targetObject = nil;
        }
        else {
            _targetObject = targetObject;
        }
    }
}

- (id<NSObject>)targetObject {
    if (_targetObject)
        return _targetObject;
    else
        return self;
}

- (BOOL)handleRequest:(TBSocketRequest *)request withConnection:(TBSocketConnection *)connection; {
    
}




@end
