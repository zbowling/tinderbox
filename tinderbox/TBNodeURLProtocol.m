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

static NSThread *listenerThread;

@implementation TBNodeURLProtocol {
    CFReadStreamRef _readStream;
    CFWriteStreamRef _writeStream;
    
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


+ (void)startListenerThreadIfNeeded
{
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
        
		listenerThread = [[NSThread alloc] initWithTarget:self
		                                         selector:@selector(listenerThread)
		                                           object:nil];
		[listenerThread start];
	});
}

- (void)ignore:(id)noop {}

+ (void)listenerThread
{
 
    @autoreleasepool {
        // We can't run the run loop unless it has an associated input source or a timer.
        // So we'll just create a timer that will never fire - unless the server runs for a decades.
        [NSTimer scheduledTimerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow]
                                         target:self
                                       selector:@selector(ignore:)
                                       userInfo:nil
                                        repeats:YES];
        
        [[NSRunLoop currentRunLoop] run];
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
    
    //NSLog(@"request: %@",[[NSString alloc] initWithData:_requestData encoding:NSUTF8StringEncoding]);
    
    
    if (![self connect]){
        [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"com.zbowling.tinderbox" code:0 userInfo:nil]];
    }
    
}

- (void) parseReadBuffer {
    
    [[self client] URLProtocol:self didLoadData:[_readBuffer copy]];
    _readLength += [_readBuffer length];
    
    _readBuffer = [NSMutableData data]; //reset read buffer in this mode
    
    if (_readLength >= _expectedLength) {
        [[self client] URLProtocolDidFinishLoading:self];
        [self close];
    }
    
    /*if (_transferEncoding && [_transferEncoding caseInsensitiveCompare:@"chunked"] == NSOrderedSame) {
        //SUPPORT HTTP 1.1
        
        if ([[[NSString alloc] initWithData:currentBody encoding:NSASCIIStringEncoding] hasSuffix:@"0\r\n\r\n"]){
            [[proto client] URLProtocolDidFinishLoading:proto];
            [proto close];
        }
    }
    else {

    }*/

}

static void CFReadStreamCallback (CFReadStreamRef stream, CFStreamEventType type, void *pInfo)
{
    TBNodeURLProtocol *proto = (__bridge TBNodeURLProtocol *)CFRetain(pInfo);
    if (type == kCFStreamEventOpenCompleted) {
        //NSLog(@"read: kCFStreamEventOpenCompleted");
    }
    else if (type == kCFStreamEventHasBytesAvailable) {
        //NSLog(@"read: kCFStreamEventHasBytesAvailable");
        uint8_t buf[1024];
        bzero(buf, 1024);
        NSUInteger len = 0;
        len = CFReadStreamRead(stream,buf,1024);
        if (len) {
            if (!proto->_hasHeader)
            {
                if (proto->_responseMessage != NULL){
                    CFHTTPMessageAppendBytes(proto->_responseMessage, buf, len);
                    if (CFHTTPMessageIsHeaderComplete(proto->_responseMessage)) {
                        proto->_hasHeader = YES;
                        

                        NSInteger statusCode = CFHTTPMessageGetResponseStatusCode(proto->_responseMessage);
                        NSDictionary *headerFields = (__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields(proto->_responseMessage);
                        NSHTTPURLResponse *urlResponse = 
                            [[NSHTTPURLResponse alloc] initWithURL:[[proto request] URL] statusCode:statusCode HTTPVersion:@"HTTP/1.0" headerFields:headerFields];
                        
                        NSData *responseData = (__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage(proto->_responseMessage);    
                        
                        NSLog(@"response: %@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                        
                        
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
                                request = [[proto request] mutableCopy];
                                [request setURL:url];
                            } else {
                                request = [[NSMutableURLRequest alloc] initWithURL:url];
                            }
                            
                            [[proto client] URLProtocol:proto wasRedirectedToRequest:request redirectResponse:urlResponse];
                            [proto close];
                        }
                        else {
                            [[proto client] URLProtocol:proto didReceiveResponse:urlResponse cacheStoragePolicy:NSURLCacheStorageAllowed];
                            //NSLog(@"didReceiveResponse %@",urlResponse);
                            
                            proto->_transferEncoding = [headerFields objectForKey:@"Transfer-Encoding"];
                            proto->_expectedLength = [urlResponse expectedContentLength];
                            proto->_readLength = 0;
                            
                            NSData *currentBody = (__bridge_transfer NSData *)CFHTTPMessageCopyBody(proto->_responseMessage);
                            
                            if (currentBody || [currentBody length] > 0) {
                                [proto->_readBuffer appendData:currentBody];
                                [proto parseReadBuffer];
                            }
                            
                            //NSLog(@"body: %@",[[NSString alloc] initWithData:currentBody encoding:NSUTF8StringEncoding]);
                        }

                        
                        if (proto->_responseMessage)
                            CFRelease(proto->_responseMessage), proto->_responseMessage = NULL;
                    }
                }
            }
            else {
                NSData *data = [NSData dataWithBytes:buf length:len];
                [proto->_readBuffer appendData:data];
                [proto parseReadBuffer];
            }
        }
    }
    else if (type == kCFStreamEventErrorOccurred)
    {
        //NSLog(@"read: kCFStreamEventErrorOccurred");
        NSError *error = (__bridge_transfer NSError *)CFReadStreamCopyError(stream);
        [[proto client] URLProtocol:proto didFailWithError:error];
        NSLog(@"error %@",error);
        [proto close];
    }
    else if (type == kCFStreamEventEndEncountered)
    {
        if (!proto->_hasHeader) {
            NSError *error = [NSError errorWithDomain:@"com.zbowling.tinderbox" code:0 userInfo:nil];
            [[proto client] URLProtocol:proto didFailWithError:error];
        }
        else {
            //NSLog(@"read: kCFStreamEventEndEncountered");
            [[proto client] URLProtocolDidFinishLoading:proto];
        }
        [proto close];
    }
    CFRelease(pInfo);
}

static void CFWriteStreamCallback (CFWriteStreamRef stream, CFStreamEventType type, void *pInfo)
{
    TBNodeURLProtocol *proto = (__bridge TBNodeURLProtocol *)CFRetain(pInfo);
    if (type == kCFStreamEventOpenCompleted) {
        //NSLog(@"write: kCFStreamEventOpenCompleted");
    }
    else if (type == kCFStreamEventCanAcceptBytes) {
        //NSLog(@"write: kCFStreamEventCanAcceptBytes");
        uint8_t *readBytes = (uint8_t *)[proto->_requestData bytes];
        readBytes += proto->_byteIndex; // instance variable to move pointer
        NSUInteger data_len = [proto->_requestData length];
        NSUInteger len = ((data_len - proto->_byteIndex >= 1024) ? 1024 : (data_len-proto->_byteIndex));
        if (len > 0) {
            len = CFWriteStreamWrite(stream, readBytes, len);
            proto->_byteIndex += len;
        }
    }
    else if (type == kCFStreamEventErrorOccurred)
    {
        //NSLog(@"write: kCFStreamEventErrorOccurred");
        NSError *error = (__bridge_transfer NSError *)CFWriteStreamCopyError(stream);
        [[proto client] URLProtocol:proto didFailWithError:error];
        [proto close];
    }
    else if (type == kCFStreamEventEndEncountered)
    {
        //NSLog(@"write: kCFStreamEventEndEncountered");
        [[proto client] URLProtocolDidFinishLoading:proto];
        [proto close];
    }
    CFRelease(pInfo);
}



- (BOOL)connect {
    
    struct sockaddr_un *sockaddr = malloc(sizeof(struct sockaddr_un));
    bzero(sockaddr, sizeof(struct sockaddr_un));
    sockaddr->sun_family = AF_UNIX;
    strncpy(sockaddr->sun_path, [[[TBNodeServer sharedServer] serverSocketPath] cStringUsingEncoding:NSUTF8StringEncoding],104);
    CFDataRef address = CFDataCreateWithBytesNoCopy(NULL, (const UInt8 *)sockaddr, sizeof(struct sockaddr_un), NULL);
    CFSocketSignature signature = { AF_UNIX, SOCK_STREAM, 0, address };
    
    CFStreamCreatePairWithPeerSocketSignature(NULL, &signature, &_readStream, &_writeStream);
    CFRelease(address);
    if (_readStream != NULL && _writeStream != NULL) {
        
        CFReadStreamSetProperty(_readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        CFWriteStreamSetProperty(_writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);


        _streamContext.version = 0;
        _streamContext.info = (__bridge void *) self;
        _streamContext.retain = nil;
        _streamContext.release = nil;
        _streamContext.copyDescription = nil;
        
        CFOptionFlags readStreamEvents = kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered | kCFStreamEventHasBytesAvailable  | kCFStreamEventOpenCompleted;
        
        if (!CFReadStreamSetClient(_readStream, readStreamEvents, &CFReadStreamCallback, &_streamContext))
        {
            return NO;
        }
        
        CFOptionFlags writeStreamEvents = kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered | kCFStreamEventCanAcceptBytes | kCFStreamEventOpenCompleted;
        
        if (!CFWriteStreamSetClient(_writeStream, writeStreamEvents, &CFWriteStreamCallback, &_streamContext))
        {
            return NO;
        }
        
        CFReadStreamScheduleWithRunLoop(_readStream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
		CFWriteStreamScheduleWithRunLoop(_writeStream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        
        
        CFStreamStatus readStatus = CFReadStreamGetStatus(_readStream);
        CFStreamStatus writeStatus = CFWriteStreamGetStatus(_writeStream);
        
        if ((readStatus == kCFStreamStatusNotOpen) || (writeStatus == kCFStreamStatusNotOpen))
        {
            CFWriteStreamOpen(_writeStream);
            CFReadStreamOpen(_readStream);
        }
    }
    else{
        return NO;
    }

    return YES;
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
    if (_readStream != NULL)
    {
        CFReadStreamUnscheduleFromRunLoop(_readStream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        CFReadStreamClose(_readStream),_readStream = NULL;
    }
    
    if (_writeStream != NULL)
    {
        CFWriteStreamUnscheduleFromRunLoop(_writeStream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        CFWriteStreamClose(_writeStream),_writeStream = NULL;
    }
    
    if (_responseMessage != NULL)
    {
        CFRelease(_responseMessage), _responseMessage=NULL;
    }

}

- (void)dealloc {
    [self close];
}



@end
