//
//  TBAppDelegate.m
//  tinderbox
//
//  Created by Zac Bowling on 12/24/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBAppDelegate.h"
#import "TBNodeServer.h"
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
    [TBNodeServer sharedServer];
    [NSURLProtocol registerClass:[TBNodeURLProtocol class]];
    [[NSNotificationCenter defaultCenter] addObserverForName:TBNodeServerDidStartNotification object:[TBNodeServer sharedServer] queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
        _lobbyWindow = [[TBNodeWindowController alloc] initWithWindowNibName:nil defaultURL:[NSURL URLWithString:@"http://tinderbox.local/main"]];
        [_lobbyWindow showWindow:self];
        
    }];
    
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[TBNodeServer sharedServer] stopServer];
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
