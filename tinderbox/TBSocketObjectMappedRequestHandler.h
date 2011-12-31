//
//  TBSocketObjectMappedRequestHandler.h
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TBSocketRequestHandler.h"
@interface TBSocketObjectMappedRequestHandler : NSObject<TBSocketRequestHandler>

@property (nonatomic,retain) id<NSObject> targetObject;

@end
