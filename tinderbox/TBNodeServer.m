//
//  TBNodeServer.m
//  tinderbox
//
//  Created by Zac Bowling on 12/24/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBNodeServer.h"
#import "NSFileManager+TB.h"


NSString * const TBNodeServerDidStartNotification = @"TBNodeServerDidStartNotification";
NSString * const TBNodeServerDidErrorNotification = @"TBNodeServerDidErrorNotification";
NSString * const TBNodeServerLogNotification = @"TBNodeServerLogNotification";

@interface TBNodeServer()

- (void)startServer;

@end

@implementation TBNodeServer {
    NSTask *_task;
    NSFileHandle *_outFile;
    NSFileHandle *_errFile;
    NSString *_scriptPath;
    NSMutableString *_outputBuffer;
    BOOL _shouldStop;
}


+ (id)sharedServer {
    static TBNodeServer *sharedServer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedServer = [[TBNodeServer alloc] initWithScriptPath:@"app.js"];
    });
    return sharedServer;
}

- (id)initWithScriptPath:(NSString *)scriptPath {
    self = [super init];
    if (self) {
        _scriptPath = scriptPath;
        _shouldStop = NO;
        _outputBuffer = [NSMutableString string];
        if ([self isServerRunning]) {
            [self stopServer];
        }
        [self startServer];
    }
    return self;
}

+ (NSURL *)nodeProcessURL {
    return [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Resources/node/bin/node"];
}

+ (NSURL *)scriptDirectory {
    return [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Resources/server" isDirectory:YES];
}

- (NSString *)serverSocketPath {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [[fm applicationSupportDirectory] stringByAppendingPathComponent:[_scriptPath stringByAppendingPathExtension:@"sock"]];
}

- (NSString *)serverPidFilePath {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [[fm applicationSupportDirectory] stringByAppendingPathComponent:[_scriptPath stringByAppendingPathExtension:@"pid"]];
}

- (BOOL)isServerRunning {
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
        NSString *s = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding: NSUTF8StringEncoding];
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

- (void)startServer {
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

-(void)stopServer {
    _shouldStop = YES;
    if (_task) {
        [_task terminate];
        _task = nil;
        sleep(1); //sigh...
    }
    
    if ([self isServerRunning])
    {
        kill([self readProcessIdentiferFromDisk], SIGKILL);
    }
}

-(void)dealloc
{
    if (_task) {
        [_task terminate];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
