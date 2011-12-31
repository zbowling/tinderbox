//
//  TBSocketRoute.h
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TBSocketHandler;

@interface TBSocketRoute : NSObject

- (id)initWithRegexString:(NSString *)regexString socketHandler:(TBSocketHandler *)handler;
- (id)initWithRegularExpression:(NSRegularExpression *)regex socketHandler:(TBSocketHandler *)handler;

@property (readonly, strong) TBSocketHandler *socketHandler;
@property (readonly, strong) NSRegularExpression *routeRegularExpression;

@end
