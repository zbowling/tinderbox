//
//  TBURLProtocol.m
//  tinderbox
//
//  Created by Zac Bowling on 12/25/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBNodeURLProtocol.h"
#import "TBNodeServer.h"

#include <sys/types.h>
#include <sys/un.h>
#include <sys/socket.h>

@interface TBNodeURLProtocol(Private)

+ (void)startListenerThreadIfNeeded;

+ (void)listenerThread;


- (BOOL)connect;
- (void)close;

@end

@implementation TBNodeURLProtocol {
    NSInputStream *_readStream;
    NSOutputStream *_writeStream;
    NSData *_requestData;
    NSUInteger _byteIndex;
    CFHTTPMessageRef _responseMessage;
    BOOL _hasHeader;
    NSURL *_rewritenURL;
    CFStreamClientContext _streamContext;
    long long _expectedLength;
    long long _readLength;
    NSString *_transferEncoding;
    NSMutableData *_readBuffer;
}

+ (NSString *)protocolScheme {
    return @"tinderbox";
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    
    NSString *host = [[request URL] host];
    if (host && [host caseInsensitiveCompare:@"tinderbox.local"] == NSOrderedSame)
    {
        return YES;
    }
    
    NSString *scheme = [[request URL] scheme];
    return ([scheme caseInsensitiveCompare: [self protocolScheme]] == NSOrderedSame );
}

+(NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    
    return request;
}


+ (NSThread *)networkThread
{
    static NSThread *networkThread;
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		networkThread = [[NSThread alloc] initWithTarget:self
		                                         selector:@selector(networkRequestThreadEntryPoint)
		                                           object:nil];
		[networkThread start];
	});
    return networkThread;
}

+ (void)networkRequestThreadEntryPoint
{
    @autoreleasepool {
        @try {
            [[NSRunLoop currentRunLoop] run];
        }
        @catch  (NSException * exception){
            NSLog(@"exception %@", exception);
        }
        @finally {
            
        }
    }

}

- (id) initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client {
    self = [super initWithRequest:request cachedResponse:cachedResponse client:client];
    if (self) {
        _byteIndex = 0;
        _responseMessage = NULL;
        _writeStream = NULL;
        _readStream = NULL;
        _readBuffer = [NSMutableData data];
    }
    return self;
}




- (void)startLoading {
    _responseMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
    NSURLRequest *request = [self request];
    id<NSURLProtocolClient> client = [self client];
    if ([request.URL host]) {
        _rewritenURL = [NSURL URLWithString:[NSString stringWithFormat:@"http:%@",[request.URL resourceSpecifier]]];
    }
    else {
        NSString *resource = [request.URL resourceSpecifier];
        
        if ([resource hasPrefix:@"//"])
        {
            resource = [resource substringFromIndex:2];
        }
        
        _rewritenURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://tinderbox.local%@",resource]];
    }
    
    CFHTTPMessageRef httpRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (__bridge CFStringRef )request.HTTPMethod, (__bridge CFURLRef)_rewritenURL,
                                                            kCFHTTPVersion1_0); //CHANGE TO kCFHTTPVersion1_1 later
    
    CFHTTPMessageSetBody(httpRequest, (__bridge CFDataRef )request.HTTPBody);
    
    [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        //ignore caching for now
        if ([key caseInsensitiveCompare:@"If-Modified-Since"] != NSOrderedSame &&
            [key caseInsensitiveCompare:@"If-None-Match"] != NSOrderedSame &&
            [key caseInsensitiveCompare:@"Cache-Control"] != NSOrderedSame)
            CFHTTPMessageSetHeaderFieldValue(httpRequest, (__bridge CFStringRef )key, (__bridge CFStringRef )obj);
    }];
    
    _requestData = (__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage(httpRequest);    
    
    NSLog(@"request: %@",[[NSString alloc] initWithData:_requestData encoding:NSUTF8StringEncoding]);
    
    
    if (![self connect]){
        //TODO need a better error
        [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"com.zbowling.tinderbox" code:0 userInfo:nil]];
    }
    
}

- (void) parseReadBuffer {
    
    if (_transferEncoding && [_transferEncoding caseInsensitiveCompare:@"chunked"] == NSOrderedSame) {
        //SUPPORT HTTP 1.1
        while (true) {
            if (_expectedLength == 0) {
                char *buf = (char *)[_readBuffer bytes];
                char *newline = strstr(buf, "\r\n");
                if (newline) {
                    int d;
                    if (sscanf(buf, "%d", &d) != 1) {
                        break;
                    }
                    if (d == 0){
                        [[self client] URLProtocolDidFinishLoading:self];
                        [self close];
                        return;
                    }
                    [_readBuffer replaceBytesInRange:NSMakeRange(0, newline-buf) withBytes:NULL length:0]; 
                    _expectedLength = d;
                }
                else {
                    break;
                }

            }
            else {
                if ([_readBuffer length] > _expectedLength) {
                    [[self client] URLProtocol:self didLoadData:[NSData dataWithBytes:[_readBuffer bytes] length:_expectedLength]];
                    [_readBuffer replaceBytesInRange:NSMakeRange(0, _expectedLength) withBytes:NULL length:0]; 
                    _expectedLength = 0;
                }
                else {
                    break;
                }
            }
        }
        
        
    }
    else {
        [[self client] URLProtocol:self didLoadData:[_readBuffer copy]];
        _readLength += [_readBuffer length];
        
        [_readBuffer replaceBytesInRange:NSMakeRange(0, [_readBuffer length]) withBytes:NULL length:0]; //reset read buffer in this mode
        
        if (_expectedLength != 0 && _readLength >= _expectedLength) {
            [[self client] URLProtocolDidFinishLoading:self];
            [self close];
        }
        
    }

}

- (void)handleReadStreamHasBytesAvailable {
    NSLog(@"read: bytes");
    uint8_t buf[1024];
    bzero(buf, 1024);
    NSUInteger len = 0;
    len = [_readStream read:buf maxLength:1024];
    if (len) {
        if (!_hasHeader)
        {
            if (_responseMessage != NULL){
                CFHTTPMessageAppendBytes(_responseMessage, buf, len);
                if (CFHTTPMessageIsHeaderComplete(_responseMessage)) {
                    _hasHeader = YES;
                    
                    NSInteger statusCode = CFHTTPMessageGetResponseStatusCode(_responseMessage);
                    NSMutableDictionary *headerFields = [(__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields(_responseMessage) mutableCopy];
                    NSString *transferEncoding = [headerFields objectForKey:@"Transfer-Encoding"];
                    [headerFields removeObjectForKey:@"Transfer-Encoding"];
                    
                    NSHTTPURLResponse *urlResponse = 
                    [[NSHTTPURLResponse alloc] initWithURL:[[self request] URL] statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:headerFields];
                    
                    
                    
                    NSString *location = [headerFields objectForKey:@"Location"];
                    if (((statusCode >= 301 && statusCode <= 303) || statusCode == 307) && location) {
                        
                        NSURL *url;
                        url = [NSURL URLWithString:location];
                        if (!url){
                            //assume relative path
                            url = [NSURL URLWithString:location relativeToURL:[NSURL URLWithString:@"http://tinderbox.local/"]];
                        }
                        
                        NSMutableURLRequest *request;
                        
                        if (statusCode == 301){
                            //301s should reuse the same request.
                            request = [[self request] mutableCopy];
                            [request setURL:url];
                        } else {
                            request = [[NSMutableURLRequest alloc] initWithURL:url];
                        }
                        
                        [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:urlResponse];
                        [self close];
                    }
                    else {
                        [[self client] URLProtocol:self didReceiveResponse:urlResponse cacheStoragePolicy:NSURLCacheStorageAllowed];
                        //NSLog(@"didReceiveResponse %@",urlResponse);
                        
                        _transferEncoding = transferEncoding;
                        _expectedLength = [urlResponse expectedContentLength];
                        _readLength = 0;
                        
                        NSData *currentBody = (__bridge_transfer NSData *)CFHTTPMessageCopyBody(_responseMessage);
                        
                        if (currentBody || [currentBody length] > 0) {
                            [_readBuffer appendData:currentBody];
                            [self parseReadBuffer];
                        }
                        
                        //NSLog(@"body: %@",[[NSString alloc] initWithData:currentBody encoding:NSUTF8StringEncoding]);
                    }
                    
                    
                    if (_responseMessage)
                        CFRelease(_responseMessage), _responseMessage = NULL;
                }
            }
        }
        else {
            NSData *data = [NSData dataWithBytes:buf length:len];
            [_readBuffer appendData:data];
            [self parseReadBuffer];
        }
    }
}

- (void)handleWriteStreamCanAcceptBytes {
    uint8_t *readBytes = (uint8_t *)[_requestData bytes];
    readBytes += _byteIndex; // instance variable to move pointer
    NSUInteger data_len = [_requestData length];
    NSUInteger len = ((data_len - _byteIndex >= 1024) ? 1024 : (data_len-_byteIndex));
    if (len > 0) {
        len = [_writeStream write:readBytes maxLength:len];
        _byteIndex += len;
    }
}

- (void)handleStreamHasError:(NSStream *)stream {
    NSError *error = [stream streamError];
    [[self client] URLProtocol:self didFailWithError:error];
    NSLog(@"error %@",error);
    [self close];
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)event {
    switch (event) {
        case NSStreamEventOpenCompleted:
            /*if (stream == _readStream)
                NSLog(@"read stream opened");
            else
                NSLog(@"write stream opened");*/
            break;
        case NSStreamEventHasBytesAvailable:
            if (stream == _readStream)
                [self handleReadStreamHasBytesAvailable];
            break;
        case NSStreamEventHasSpaceAvailable:
            [self handleWriteStreamCanAcceptBytes];
            break;
        case NSStreamEventErrorOccurred:
            [self handleStreamHasError:stream];
            break;
        case NSStreamEventEndEncountered:
            if (stream == _readStream && !_hasHeader) {
                //make this error give more info
                NSError *error = [NSError errorWithDomain:@"com.zbowling.tinderbox" code:0 userInfo:nil];
                [[self client] URLProtocol:self didFailWithError:error];
            }
            else {
                [[self client] URLProtocolDidFinishLoading:self];
            }
            [self close];
        default:
            break;
    }
}


- (void)openOnNetworkThread {
    [_readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [_writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    if ([_readStream streamStatus] == NSStreamStatusNotOpen)
        [_readStream open];
    
    if ([_writeStream streamStatus] == NSStreamStatusNotOpen)
        [_writeStream open];
}

- (void)closeOnNetworkThread {
    [_readStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [_writeStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    if ([_readStream streamStatus] != NSStreamStatusClosed || [_readStream streamStatus] != NSStreamStatusError) {
        [_readStream close];
        _readStream = nil;
    }
    
    if ([_writeStream streamStatus] != NSStreamStatusClosed || [_writeStream streamStatus] != NSStreamStatusError) {
        [_writeStream close];
        _writeStream = nil;
    }
}

- (BOOL)connect {
    
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    if ([[TBNodeServer sharedServer] createStreamPairToServerWithInputStream:&inputStream outputStream:&outputStream]) {
    
        _readStream = inputStream;
        _writeStream = outputStream;
        
        _readStream.delegate = self;
        _writeStream.delegate = self;
         
        [self performSelector:@selector(openOnNetworkThread) onThread:[[self class] networkThread] withObject:nil waitUntilDone:YES];
        return YES;
    }
    
    return NO;
}

- (void)stopLoading {
    if (dispatch_get_current_queue() == dispatch_get_main_queue()) {
        [self close];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self close];
        });
    }
}


- (void)close {
    if ([NSThread currentThread] == [[self class] networkThread])
        [self closeOnNetworkThread];
    else 
        [self performSelector:@selector(openOnNetworkThread) onThread:[[self class] networkThread] withObject:nil waitUntilDone:YES];
    
    if (_responseMessage != NULL)
    {
        CFRelease(_responseMessage), _responseMessage=NULL;
    }

}

- (void)dealloc {
    [self close];
}



@end
