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
    
    NSString *_scriptPath;
    
    BOOL _shouldStop;
}


+ (id)sharedServer {
    static TBNodeServer *sharedServer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedServer = [[TBNodeServer alloc] initWithScriptPath:@"server.js"];
    });
    return sharedServer;
}

- (id)initWithScriptPath:(NSString *)scriptPath {
    self = [super init];
    if (self) {
        _scriptPath = scriptPath;
        _shouldStop = NO;
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
    return [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Resources" isDirectory:YES];
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


- (int)runningServerFileDescriptor {
    if ([self isServerRunning]) {
        return [[NSFileHandle fileHandleForWritingAtPath:[self serverSocketPath]] fileDescriptor];
    }
    else {
        return 0;
    }
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

- (void)startServer {
    
    NSString *fullScriptPath = [[[[self class] scriptDirectory] URLByAppendingPathComponent:_scriptPath] path];
    
    _task = [[NSTask alloc] init];
    _task.launchPath = [[[self class] nodeProcessURL] path];
    _task.currentDirectoryPath = [[[self class] scriptDirectory] path];
    _task.arguments = [NSArray arrayWithObjects:
                       fullScriptPath,
                       [self serverSocketPath],
                       nil];
#if DEBUG
    _task.standardInput = [NSFileHandle fileHandleWithStandardInput];
    _task.standardOutput = [NSFileHandle fileHandleWithStandardOutput];
    _task.standardError = [NSFileHandle fileHandleWithStandardError];
#endif
    
    
    [_task launch];
    sleep(3);
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
