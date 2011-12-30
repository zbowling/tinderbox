//
//  TBAppDelegate.m
//  tinderbox
//
//  Created by Zac Bowling on 12/24/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBAppDelegate.h"
#import "TBNodeProcess.h"
#import "TBNodeURLProtocol.h"
#import "TBNodeWindowController.h"
#import "TBRoomWindowController.h"

@implementation TBAppDelegate {
    TBNodeWindowController *_lobbyWindow;
    NSMutableDictionary *_roomWindows;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _roomWindows = [NSMutableDictionary dictionary];
    [TBNodeProcess sharedProcess];
    [NSURLProtocol registerClass:[TBNodeURLProtocol class]];
    [[NSNotificationCenter defaultCenter] addObserverForName:TBNodeServerDidStartNotification object:[TBNodeProcess sharedProcess] queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
        _lobbyWindow = [[TBNodeWindowController alloc] initWithWindowNibName:nil defaultURL:[NSURL URLWithString:@"http://tinderbox.local/main"]];
        [_lobbyWindow showWindow:self];
        
    }];
    
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[TBNodeProcess sharedProcess] stopProcess];
}

- (void)showRoomWindowWithRoomID:(NSString *)roomID {
    TBRoomWindowController *roomWindowController = [_roomWindows objectForKey:roomID];
    if (!roomWindowController){
        NSURL *url = [NSURL URLWithString:[@"http://tinderbox.local/room" stringByAppendingPathComponent:roomID]];
        roomWindowController = [[TBRoomWindowController alloc] initWithWindowNibName:nil defaultURL:url];
        [_roomWindows setObject:roomWindowController forKey:roomID];
    }
    [roomWindowController showWindow:self];
    [[roomWindowController window] makeKeyAndOrderFront:self];
}

@end
