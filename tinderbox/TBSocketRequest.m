//
//  TBNodeCallbackRequest.m
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBSocketRequest.h"
#import "TBSocketConnection.h"

@implementation TBSocketRequest {
    CFHTTPMessageRef _requestRef;
    CFHTTPMessageRef _responseRef;
    TBSocketConnection *_connection;
    NSInputStream *_responseStream;
}

@synthesize responseBodyStream=_responseStream;

- (id)initWithRequest:(CFHTTPMessageRef)requestRef connection:(TBSocketConnection *)connnection
{
    self = [super init];
    if (self)
    {
        _requestRef = (CFHTTPMessageRef)CFRetain(requestRef);
        _connection = connnection;
    }
    return self;
}

- (void)dealloc 
{
    if (_requestRef != NULL)
        CFRelease(_requestRef), _requestRef = NULL;
    if (_responseRef != NULL)
        CFRelease(_responseRef), _responseRef = NULL;
}


- (TBSocketConnection *)connection {
    return _connection;
}

- (CFHTTPMessageRef)request {
    return _requestRef;
}

- (CFHTTPMessageRef)response {
    return _responseRef;
}

- (void)setResponse:(CFHTTPMessageRef)value {
    if (value != _responseRef) {
        if (_responseRef) CFRelease(_responseRef);
        _responseRef = (CFHTTPMessageRef)CFRetain(value);
        if (_responseRef) {
            // check to see if the response can now be sent out
            [_connection processOutgoingBytes];
        }
    }
}


@end
