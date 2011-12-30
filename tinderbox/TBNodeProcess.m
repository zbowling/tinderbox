//
//  TBNodeServer.m
//  tinderbox
//
//  Created by Zac Bowling on 12/24/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBNodeProcess.h"
#import "NSFileManager+TB.h"
#include <sys/types.h>
#include <sys/un.h>
#include <sys/socket.h>


NSString * const TBNodeServerDidStartNotification = @"TBNodeServerDidStartNotification";
NSString * const TBNodeServerDidErrorNotification = @"TBNodeServerDidErrorNotification";
NSString * const TBNodeServerLogNotification = @"TBNodeServerLogNotification";

@interface TBNodeProcess()

- (void)startProcess;

@end

@implementation TBNodeProcess {
    NSTask *_task;
    NSFileHandle *_outFile;
    NSFileHandle *_errFile;
    NSString *_scriptPath;
    NSMutableString *_outputBuffer;
    BOOL _shouldStop;
}


+ (id)sharedProcess {
    static TBNodeProcess *sharedServer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedServer = [[TBNodeProcess alloc] initWithScriptPath:@"app.js"];
    });
    return sharedServer;
}

- (id)initWithScriptPath:(NSString *)scriptPath {
    self = [super init];
    if (self) {
        _scriptPath = scriptPath;
        _shouldStop = NO;
        _outputBuffer = [NSMutableString string];
        if ([self isProcessRunning]) {
            [self stopProcess];
        }
        [self startProcess];
    }
    return self;
}

+ (NSURL *)nodeProcessURL {
    return [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Resources/node/bin/node"];
}

+ (NSURL *)scriptDirectory {
    return [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Resources/server" isDirectory:YES];
}

- (NSString *)callbackSocketPath {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [[fm applicationSupportDirectory] stringByAppendingPathComponent:[_scriptPath stringByAppendingPathExtension:@"callback"]];
}

- (NSString *)serverSocketPath {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [[fm applicationSupportDirectory] stringByAppendingPathComponent:[_scriptPath stringByAppendingPathExtension:@"server"]];
}

- (NSString *)serverPidFilePath {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [[fm applicationSupportDirectory] stringByAppendingPathComponent:[_scriptPath stringByAppendingPathExtension:@"pid"]];
}

- (BOOL)isProcessRunning {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:[self serverSocketPath]])
    {
        return [fm isWritableFileAtPath:[self serverSocketPath]];
    }
    return NO;
}

- (void)writeTaskProcessIdentiferToDisk {
    NSError *error;
    if (![[NSString stringWithFormat:@"%i",[_task processIdentifier]] writeToFile:[self serverPidFilePath] atomically:YES encoding:NSASCIIStringEncoding error:&error]) {
        NSLog(@"unable to write pid to file %@",error);
    }
}

- (int)readProcessIdentiferFromDisk {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:[self serverPidFilePath]]) {
        return 0;
    }
    
    NSError *error;
    NSString *pidString;
    if (!(pidString = [NSString stringWithContentsOfFile:[self serverPidFilePath] encoding:NSASCIIStringEncoding error:&error]))
    {
        NSLog(@"unable to read pid frome file %@",error);
        return 0;
    };
    
    return [pidString intValue];
}


-(void) appendDataFrom:(NSFileHandle*)fileHandle to:(NSMutableString*)output
{
    
    NSData *data = [fileHandle availableData];
    if ([data length]) {
        NSString *s = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
        [output appendString:s];
    }
}

-(void) outData: (NSNotification *) notification
{
    NSMutableString *output = [NSMutableString string];
    NSFileHandle *fileHandle = (NSFileHandle*) [notification object];
    [self appendDataFrom:fileHandle to:output];
    if ([output hasPrefix:@"OK"])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:TBNodeServerDidStartNotification object:self userInfo:nil];
    }
    NSLog(@"%@",output);
    [fileHandle waitForDataInBackgroundAndNotify];
}

-(void) errData: (NSNotification *) notification
{
    NSMutableString *output = [NSMutableString string];
    NSFileHandle *fileHandle = (NSFileHandle*) [notification object];
    [self appendDataFrom:fileHandle to:output];
    NSLog(@"%@",output);
    [fileHandle waitForDataInBackgroundAndNotify];
}

- (void)startProcess {
    NSString *fullScriptPath = [[[[self class] scriptDirectory] URLByAppendingPathComponent:_scriptPath] path];
    
    _task = [[NSTask alloc] init];
    _task.launchPath = [[[self class] nodeProcessURL] path];
    _task.currentDirectoryPath = [[[self class] scriptDirectory] path];
    _task.arguments = [NSArray arrayWithObjects:
                       fullScriptPath,
                       [self serverSocketPath],
                       nil];
    
    NSPipe *inPipe = [NSPipe pipe];
    NSPipe *outPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];

    _task.standardInput = inPipe;
    _task.standardOutput = outPipe;
    _task.standardError = errPipe;
    
    
    _outFile = [outPipe fileHandleForReading];
    _errFile = [errPipe fileHandleForReading];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(outData:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:_outFile];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(errData:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:_errFile];
    
    [_outFile waitForDataInBackgroundAndNotify];
    [_errFile waitForDataInBackgroundAndNotify];

    
    [_task launch];
    
    [self writeTaskProcessIdentiferToDisk];
}

- (void)stopProcess {
    _shouldStop = YES;
    if (_task) {
        [_task terminate];
        _task = nil;
        sleep(1); //sigh...
    }
    
    if ([self isProcessRunning])
    {
        kill([self readProcessIdentiferFromDisk], SIGKILL);
    }
}

- (BOOL)createStreamPairToServerWithInputStream:(NSInputStream **)inputStream outputStream:(NSOutputStream **)outputStream {
    return [[self class] createStreamPairToPath:[self serverSocketPath] inputStream:inputStream outputStream:outputStream];
}

+ (BOOL)createStreamPairToPath:(NSString *)path inputStream:(NSInputStream **)inputStream outputStream:(NSOutputStream **)outputStream {
    struct sockaddr_un *sockaddr = malloc(sizeof(struct sockaddr_un));
    bzero(sockaddr, sizeof(struct sockaddr_un));
    sockaddr->sun_family = AF_UNIX;
    strncpy(sockaddr->sun_path, [path cStringUsingEncoding:NSUTF8StringEncoding], 104);
    CFDataRef address = CFDataCreateWithBytesNoCopy(NULL, (const UInt8 *)sockaddr, sizeof(struct sockaddr_un), NULL);
    CFSocketSignature signature = { AF_UNIX, SOCK_STREAM, 0, address };
    
    CFReadStreamRef cfReadStream;
    CFWriteStreamRef cfWriteStream;
    
    CFStreamCreatePairWithPeerSocketSignature(NULL, &signature, &cfReadStream, &cfWriteStream);
    
    CFRelease(address);
    if (cfReadStream != NULL && cfWriteStream != NULL) {
        
        CFReadStreamSetProperty(cfReadStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        CFWriteStreamSetProperty(cfWriteStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        
        //convert over to foundation now.
        *inputStream = (__bridge_transfer NSInputStream *)cfReadStream;
        *outputStream = (__bridge_transfer NSOutputStream *)cfWriteStream;
        return YES;
    }
    return NO;
}

-(void)dealloc
{
    if (_task) {
        [_task terminate];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
