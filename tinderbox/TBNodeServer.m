//
//  TBNodeServer.m
//  tinderbox
//
//  Created by Zac Bowling on 12/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TBNodeServer.h"

NSString * const TBNodeServerDidStartNotification = @"TBNodeServerDidStartNotification";
NSString * const TBNodeServerDidErrorNotification = @"TBNodeServerDidErrorNotification";
NSString * const TBNodeServerLogNotification = @"TBNodeServerLogNotification";

@interface TBNodeServer()

- (void)readOutputNotification:(NSNotification *)note;
- (void)readErrorNotification:(NSNotification *)note;

- (void)startServer;

@end

@implementation TBNodeServer {
    NSTask *_task;
    NSPipe *_pipe;
    NSFileHandle *_error;
    
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


- (void)startServer {
    
    NSString *fullScriptPath = [[[[self class] scriptDirectory] URLByAppendingPathComponent:_scriptPath] path];
    
    _pipe = [NSPipe pipe];
    //_error = [NSFileHandle fileHandleWithStandardError];
    
    _task = [[NSTask alloc] init];
    _task.launchPath = [[[self class] nodeProcessURL] path];
    _task.currentDirectoryPath = [[[self class] scriptDirectory] path];
    _task.arguments = [NSArray arrayWithObjects:
                       fullScriptPath, nil];
    
    _task.standardInput = _pipe;
    _task.standardOutput = _pipe;
    //_task.standardError = _error;
    
    
    /*_pipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *input){
        NSData *data = [input availableData];
        
        
        NSString *text = [[NSString alloc] initWithData:data 
                                               encoding:NSUTF8StringEncoding];
        
        NSLog(@"node: %@", text);
    };*/
    
    [_task launch];
    
}

-(void) stopServer {
    _shouldStop = YES;
    [_task interrupt];
    [_task terminate];
    _task = nil;
}

-(void)dealloc
{
    if (_task) {
        [_task terminate];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
