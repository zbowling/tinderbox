//
//  TBNodeServer.h
//  tinderbox
//
//  Created by Zac Bowling on 12/24/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const TBNodeServerDidStartNotification;
extern NSString * const TBNodeServerDidErrorNotification;
extern NSString * const TBNodeServerLogNotification;


@interface TBNodeServer : NSObject

+ (id)sharedServer;

+ (NSURL *)nodeProcessURL;

- (id)initWithScriptPath:(NSString *)scriptPath;

- (NSString *)serverSocketPath;

- (BOOL)isServerRunning;

- (void)stopServer;

@end
