//
//  TBSocketResponse.m
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBSocketResponse.h"

@implementation TBSocketResponse {
    CFHTTPMessageRef _responseRef;
    NSInputStream *_responseBodyStream;
}

@synthesize HTTPMessage = _responseRef;
@synthesize responseBodyStream = _responseBodyStream;

-(id)initWithStatusCode:(NSInteger)statusCode HTTPVersion:(NSString*)HTTPVersion headerFields:(NSDictionary*)headerFields responseBodyStream:(NSInputStream *)responseBodyStream {
    self = [self initWithStatusCode:statusCode HTTPVersion:HTTPVersion headerFields:headerFields];
    if (self) {
        _responseBodyStream = responseBodyStream;
    }
    return self;
}


-(id)initWithStatusCode:(NSInteger)statusCode HTTPVersion:(NSString*)HTTPVersion headerFields:(NSDictionary*)headerFields body:(NSData *)body {
    self = [self initWithStatusCode:statusCode HTTPVersion:HTTPVersion headerFields:headerFields];
    if (self) {
        CFHTTPMessageSetBody(_responseRef, (__bridge CFDataRef)body);
    }
    return self;
}

-(id)initWithStatusCode:(NSInteger)statusCode HTTPVersion:(NSString*)HTTPVersion headerFields:(NSDictionary*)headerFields {
    self = [super init];
    if (self) {
        _responseRef = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, NULL, (__bridge CFStringRef)HTTPVersion);
        [headerFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            CFHTTPMessageSetHeaderFieldValue(_responseRef, (__bridge CFStringRef) key, (__bridge CFStringRef) obj);
        }];
    }
    return self;
}


-(void)dealloc {
    if (_responseRef != NULL)
        CFRelease(_responseRef), _responseRef = NULL;
}






@end
