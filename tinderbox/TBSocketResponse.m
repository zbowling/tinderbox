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

+(id)serverErrorResponseWithError:(NSError *)error {
    
    NSError *outerr;
    NSData *data = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObject:[error description] forKey:@"error"] 
                                                   options:NSJSONWritingPrettyPrinted 
                                                     error:&outerr];
    
    return [self responseWithStatusCode:500 contentType:@"application/json" body:data];
}

+(id)serverErrorResponseWithString:(NSString *)errorString {
    NSError *outerr;
    NSData *data = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObject:errorString forKey:@"error"] 
                                                   options:NSJSONWritingPrettyPrinted 
                                                     error:&outerr];
    
    return [self responseWithStatusCode:500 contentType:@"application/json" body:data];
}


+(id)redirectResponseWithLocation:(NSString *)location {
    NSDictionary *headers = [NSDictionary dictionaryWithObject:location forKey:@"Location"];
    return [[self alloc] initWithStatusCode:302 HTTPVersion:(NSString *)kCFHTTPVersion1_1 headerFields:headers];
}

+(id)responseWithStatusCode:(NSInteger)statusCode {
    return [[self alloc] initWithStatusCode:statusCode HTTPVersion:(NSString *)kCFHTTPVersion1_1 headerFields:nil];
}

+(id)responseWithStatusCode:(NSInteger)statusCode headerFields:(NSDictionary *)headerFields body:(NSData *)body {
    return [[self alloc] initWithStatusCode:statusCode HTTPVersion:(NSString *)kCFHTTPVersion1_1 headerFields:headerFields body:body];
}

+(id)responseWithStatusCode:(NSInteger)statusCode contentType:(NSString *)contentType body:(NSData *)body {
    NSDictionary *headers = [NSDictionary dictionaryWithObject:contentType forKey:@"Content-Type"];
    return [[self alloc] initWithStatusCode:statusCode HTTPVersion:(NSString *)kCFHTTPVersion1_1 headerFields:headers body:body];
}


-(id)initWithStatusCode:(NSInteger)statusCode HTTPVersion:(NSString*)HTTPVersion headerFields:(NSDictionary*)headerFields responseBodyStream:(NSInputStream *)responseBodyStream {
    self = [self initWithStatusCode:statusCode HTTPVersion:HTTPVersion headerFields:headerFields];
    if (self) {
        _responseBodyStream = responseBodyStream;
    }
    return self;
}


-(id)initWithStatusCode:(NSInteger)statusCode HTTPVersion:(NSString*)HTTPVersion headerFields:(NSDictionary*)headerFields body:(NSData *)body {
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:headerFields];
    [headerFields setValue:[NSString stringWithFormat:@"%ui",[body length]] forKey:@"Content-Length"];
    self = [self initWithStatusCode:statusCode HTTPVersion:HTTPVersion headerFields:headers];
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

- (NSDictionary *)allHTTPHeaderFields {
    return (__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields(_responseRef);
}

- (NSString *)HTTPMethod {
    return (__bridge_transfer NSString *)CFHTTPMessageCopyRequestMethod(_responseRef);
}

- (NSURL *)URL {
    return (__bridge_transfer NSURL *)CFHTTPMessageCopyRequestURL(_responseRef);
}

- (NSData *)HTTPBody {
    return (__bridge_transfer NSData *)CFHTTPMessageCopyBody(_responseRef);
}

- (NSString *)HTTPVersion {
    return (__bridge_transfer NSString *)CFHTTPMessageCopyVersion(_responseRef);
}




@end
