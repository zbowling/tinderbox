//
//  TBNodeCallbackServer.m
//  tinderbox
//
//  Created by Zac Bowling on 12/28/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBNodeCallbackServer.h"
#include <sys/types.h>
#include <sys/un.h>
#include <sys/socket.h>

@implementation TBNodeCallbackServer {
    NSString *_socketPath;
    CFSocketRef _socket;
}

- (id)initWithSocketPath:(NSString *)path {
    self = [super init];
    if (self) {
        _socketPath = [path copy];
    }
    return self;
}

- (void)dealloc {
    if (_socket != NULL)
    {
        CFRelease(_socket), _socket = NULL;
    }
}

- (BOOL)cleanup:(NSError **)error {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:_socketPath]) {
        NSError *errorb;
        if (![fm removeItemAtPath:_socketPath error:&errorb])
        {
            if (error) *error = errorb;
            NSLog(@"can't cleanup older socket. error %@",errorb);
            return NO;
        }
    }
    return YES;
}



- (void)accept:(CFSocketNativeHandle)nativeSocketHandle {
    CFReadStreamRef readStream = NULL;
	CFWriteStreamRef writeStream = NULL;
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream);
    if (readStream && writeStream) {
        CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        
    }
    else {
        close(nativeSocketHandle);
    }
    if (readStream) CFRelease(readStream);
    if (writeStream) CFRelease(writeStream);
}

static void ServerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    TBNodeCallbackServer *nodeServer = (__bridge TBNodeCallbackServer *)data;
    if (kCFSocketAcceptCallBack == type) { 
        CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
        [nodeServer accept:nativeSocketHandle];
    }
}

- (BOOL)start:(NSError **)error {
    if (![self cleanup:error]) return NO;
    
    struct sockaddr_un *sockaddr = malloc(sizeof(struct sockaddr_un));
    bzero(sockaddr, sizeof(struct sockaddr_un));
    sockaddr->sun_family = AF_UNIX;
    strncpy(sockaddr->sun_path, [_socketPath cStringUsingEncoding:NSUTF8StringEncoding], 104);
    CFDataRef address = CFDataCreateWithBytesNoCopy(NULL, (const UInt8 *)sockaddr, sizeof(struct sockaddr_un), NULL);
    CFSocketSignature signature = { AF_UNIX, SOCK_STREAM, 0, address };

    CFSocketContext socketCtxt = {0, (__bridge void *)self, NULL, NULL, NULL};
    _socket = CFSocketCreateWithSocketSignature(kCFAllocatorDefault, &signature, kCFSocketAcceptCallBack, (CFSocketCallBack)&ServerAcceptCallBack, &socketCtxt);
    if (!_socket) {
        if (error) *error = [[NSError alloc] initWithDomain:@"com.zbowling.tinderbox.callback" code:0 userInfo:nil];
        if (_socket) CFRelease(_socket);
        CFRelease(address);
        return NO;
    }
    
    if (kCFSocketSuccess != CFSocketSetAddress(_socket, address))
    {
        if (error) *error = [[NSError alloc] initWithDomain:@"com.zbowling.tinderbox.callback" code:1 userInfo:nil];
        if (_socket) CFRelease(_socket);
        CFRelease(address);
        return NO;
    };
    CFRelease(address);
    
    
    CFRunLoopRef cfrl = CFRunLoopGetCurrent();
    CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
    CFRunLoopAddSource(cfrl, source, kCFRunLoopCommonModes);
    CFRelease(source);
    
    
    return YES;
}

- (BOOL)stop {
    if (_socket != NULL) {
        CFSocketInvalidate(_socket);
        CFRelease(_socket);
        _socket = NULL;
    }
    return YES;
    
}

@end
