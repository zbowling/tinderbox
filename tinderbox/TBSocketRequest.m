//
//  TBNodeCallbackRequest.m
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBSocketRequest.h"
#import "NSDictionary+TB.h"

@implementation TBSocketRequest {
    CFHTTPMessageRef _requestRef;
    TBSocketConnection *_connection;
}

@synthesize connection=_connection;

- (id)initWithHTTPMessage:(CFHTTPMessageRef)requestRef connection:(TBSocketConnection *)connection;
{
    self = [super init];
    if (self)
    {
        _connection = connection;
        _requestRef = (CFHTTPMessageRef)CFRetain(requestRef);
    }
    return self;
}

- (void)dealloc 
{
    if (_requestRef != NULL)
        CFRelease(_requestRef), _requestRef = NULL;
}


- (CFHTTPMessageRef)requestHTTPMessage {
    return _requestRef;
}

- (NSDictionary *)allHTTPHeaderFields {
    return (__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields(_requestRef);
}

- (NSString *)HTTPMethod {
    return (__bridge_transfer NSString *)CFHTTPMessageCopyRequestMethod(_requestRef);
}

- (NSURL *)URL {
    return (__bridge_transfer NSURL *)CFHTTPMessageCopyRequestURL(_requestRef);
}

- (NSData *)HTTPBody {
    return (__bridge_transfer NSData *)CFHTTPMessageCopyBody(_requestRef);
}

- (NSString *)HTTPVersion {
    return (__bridge_transfer NSString *)CFHTTPMessageCopyVersion(_requestRef);
}

- (NSDictionary *)URLQueryParams {
    return [NSDictionary dictionaryWithFormEncodedString:[[self URL] query]];
}

@end
