//
//  TBSocketRoute.m
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBSocketRoute.h"

@implementation TBSocketRoute

@synthesize routeRegularExpression=_routeRegularExpression;
@synthesize socketHandler=_socketHandler;

- (id)initWithRegexString:(NSString *)regexString socketHandler:(TBSocketHandler *)handler {
    NSRegularExpressionOptions options = NSRegularExpressionAllowCommentsAndWhitespace;
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:options error:&error];
    if (!regex) {
        NSLog(@"unable to parse route regular expression (\"%@\"). returned error %@",regexString, error);
        return nil;
    }
    return [self initWithRegularExpression:regex socketHandler:handler];
}

- (id)initWithRegularExpression:(NSRegularExpression *)regex socketHandler:(TBSocketHandler *)handler {
    NSParameterAssert(regex);
    self = [super init];
    if (self) {
        _routeRegularExpression = regex;
        _socketHandler = handler;
    }
    return self;
}

@end
