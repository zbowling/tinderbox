//
//  TBSocketConnection.m
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBSocketConnection.h"
#import "TBSocketServer.h"
#import "TBSocketRequest.h"

@implementation TBSocketConnection {
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;

    NSMutableData *_inputBuffer;
    NSMutableData *_outputBuffer;
    NSMutableArray *_requests;
    
    TBSocketServer *_server;
    
    BOOL _isValid;
    BOOL _firstResponseDone;
}

@synthesize requestReceievedHandler=_requestReceievedHandler;


- (id)initWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream socketServer:(TBSocketServer *)server {
    self = [super init];
    if (self) {
        _inputStream = inputStream;
        _inputStream.delegate = self;
        [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        _outputStream = outputStream;
        _outputStream.delegate = self;
        [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        [_inputStream open];
        [_outputStream open];
        
        _server = server;
    }
    return self;
}

- (void)dealloc {
    [self invalidate];
}

- (TBSocketServer *)server {
    return _server;
}

- (TBSocketRequest *)nextRequest {
    NSUInteger idx, cnt = _requests ? [_requests count] : 0;
    for (idx = 0; idx < cnt; idx++) {
        id obj = [_requests objectAtIndex:idx];
        if ([obj response] == nil) {
            return obj;
        }
    }
    return nil;
}

- (BOOL)isValid {
    return _isValid;
}

- (void)invalidate {
    if (_isValid) {
        _isValid = NO;
        [_inputStream close];
        [_outputStream close];
        _inputStream = nil;
        _outputStream = nil;
        _inputBuffer = nil;
        _outputBuffer = nil;
        _requests = nil;
        _requestReceievedHandler = nil;
        [_server invalidateConnection:self];
    }
}

// YES return means that a complete request was parsed, and the caller
// should call again as the buffered bytes may have another complete
// request available.
- (BOOL)processIncomingBytes {
    CFHTTPMessageRef working = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, TRUE);
    CFHTTPMessageAppendBytes(working, [_inputBuffer bytes], [_inputBuffer length]);
    
    // This "try and possibly succeed" approach is potentially expensive
    // (lots of bytes being copied around), but the only API available for
    // the server to use, short of doing the parsing itself.
    
    // HTTPConnection does not handle the chunked transfer encoding
    // described in the HTTP spec.  And if there is no Content-Length
    // header, then the request is the remainder of the stream bytes.
    
    if (CFHTTPMessageIsHeaderComplete(working)) {
        NSString *contentLengthValue = (__bridge_transfer NSString *)CFHTTPMessageCopyHeaderFieldValue(working, CFSTR("Content-Length"));
        
        unsigned contentLength = contentLengthValue ? [contentLengthValue intValue] : 0;
        NSData *body = (__bridge_transfer NSData *)CFHTTPMessageCopyBody(working);
        NSUInteger bodyLength = [body length];
        if (contentLength <= bodyLength) {
            NSData *newBody = [NSData dataWithBytes:[body bytes] length:contentLength];
            [_inputBuffer setLength:0];
            [_inputBuffer appendBytes:([body bytes] + contentLength) length:(bodyLength - contentLength)];
            CFHTTPMessageSetBody(working, (__bridge CFDataRef)newBody);
        } else {
            CFRelease(working);
            return NO;
        }
    } else {
        return NO;
    }
    
    TBSocketRequest *request = [[TBSocketRequest alloc] initWithRequest:working connection:self];
    if (!_requests) {
        _requests = [[NSMutableArray alloc] init];
    }
    [_requests addObject:request];
    
    if (self.requestReceievedHandler) {
        self.requestReceievedHandler(request);
    }
    else {
        [self performDefaultRequestHandling:request];
    }
    
    CFRelease(working);
    return YES;
}

- (void)processOutgoingBytes {
    // The HTTP headers, then the body if any, then the response stream get
    // written out, in that order.  The Content-Length: header is assumed to 
    // be properly set in the response.  Outgoing responses are processed in 
    // the order the _requests were received (required by HTTP).
    
    // Write as many bytes as possible, from buffered bytes, response
    // headers and body, and response stream.
    
    if (![_outputStream hasSpaceAvailable]) {
        return;
    }
    
    NSUInteger olen = [_outputBuffer length];
    if (0 < olen) {
        NSInteger writ = [_outputStream write:[_outputBuffer bytes] maxLength:olen];
        // buffer any unwritten bytes for later writing
        if (writ < olen) {
            memmove([_outputBuffer mutableBytes], [_outputBuffer mutableBytes] + writ, olen - writ);
            [_outputBuffer setLength:olen - writ];
            return;
        }
        [_outputBuffer setLength:0];
    }
    
    NSUInteger cnt = _requests ? [_requests count] : 0;
    TBSocketRequest *req = (0 < cnt) ? [_requests objectAtIndex:0] : nil;
    
    CFHTTPMessageRef cfresp = req ? [req response] : NULL;
    if (!cfresp) return;
    
    if (!_outputBuffer) {
        _outputBuffer = [[NSMutableData alloc] init];
    }
    
    if (!_firstResponseDone) {
        _firstResponseDone = YES;
        NSData *serialized = (__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage(cfresp);
        NSUInteger olen = [serialized length];
        if (0 < olen) {
            NSInteger writ = [_outputStream write:[serialized bytes] maxLength:olen];
            if (writ < olen) {
                // buffer any unwritten bytes for later writing
                [_outputBuffer setLength:(olen - writ)];
                memmove([_outputBuffer mutableBytes], [serialized bytes] + writ, olen - writ);
                return;
            }
        }
    }
    
    NSInputStream *respStream = [req responseBodyStream];
    if (respStream) {
        if ([respStream streamStatus] == NSStreamStatusNotOpen) {
            [respStream open];
        }
        // read some bytes from the stream into our local buffer
        [_outputBuffer setLength:16 * 1024];
        NSInteger read = [respStream read:[_outputBuffer mutableBytes] maxLength:[_outputBuffer length]];
        [_outputBuffer setLength:read];
    }
    
    if (0 == [_outputBuffer length]) {
        // When we get to this point with an empty buffer, then the 
        // processing of the response is done. If the input stream
        // is closed or at EOF, then no more _requests are coming in.
        [_requests removeObjectAtIndex:0];
        _firstResponseDone = NO;
        if ([_inputStream streamStatus] == NSStreamStatusAtEnd && [_requests count] == 0) {
            [self invalidate];
        }
        return;
    }
    
    olen = [_outputBuffer length];
    if (0 < olen) {
        NSInteger writ = [_outputStream write:[_outputBuffer bytes] maxLength:olen];
        // buffer any unwritten bytes for later writing
        if (writ < olen) {
            memmove([_outputBuffer mutableBytes], [_outputBuffer mutableBytes] + writ, olen - writ);
        }
        [_outputBuffer setLength:olen - writ];
    }
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)streamEvent {
    switch(streamEvent) {
        case NSStreamEventHasBytesAvailable:;
            uint8_t buf[16 * 1024];
            uint8_t *buffer = NULL;
            NSUInteger len = 0;
            if (![_inputStream getBuffer:&buffer length:&len]) {
                NSInteger amount = [_inputStream read:buf maxLength:sizeof(buf)];
                buffer = buf;
                len = amount;
            }
            if (0 < len) {
                if (!_inputBuffer) {
                    _inputBuffer = [[NSMutableData alloc] init];
                }
                [_inputBuffer appendBytes:buffer length:len];
            }
            do {} while ([self processIncomingBytes]);
            break;
        case NSStreamEventHasSpaceAvailable:;
            [self processOutgoingBytes];
            break;
        case NSStreamEventEndEncountered:;
            [self processIncomingBytes];
            if (stream == _outputStream) {
                // When the output stream is closed, no more writing will succeed and
                // will abandon the processing of any pending _requests and further
                // incoming bytes.
                [self invalidate];
            }
            break;
        case NSStreamEventErrorOccurred:;
            NSLog(@"TBSocketStream stream error: %@", [stream streamError]);
            break;
        default:
            break;
    }
}

- (void)performDefaultRequestHandling:(TBSocketRequest *)message {
    CFHTTPMessageRef request = [message request];
    
    NSString *vers = (__bridge_transfer NSString *)CFHTTPMessageCopyVersion(request);
    if (!vers || ![vers isEqual:(id)kCFHTTPVersion1_1]) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 505, NULL, (__bridge CFStringRef)vers); // Version Not Supported
        [message setResponse:response];
        CFRelease(response);
        return;
    }
    
    NSString *method = (__bridge_transfer id)CFHTTPMessageCopyRequestMethod(request);
    if (!method) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1); // Bad Request
        [message setResponse:response];
        CFRelease(response);
        return;
    }
    
    if ([method isEqual:@"GET"] || [method isEqual:@"HEAD"]) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 404, NULL, kCFHTTPVersion1_1); // Not Found
        [message setResponse:response];
        CFRelease(response);
        return;
    }
    
    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 405, NULL, kCFHTTPVersion1_1); // Method Not Allowed
    [message setResponse:response];
    CFRelease(response);
}

@end

