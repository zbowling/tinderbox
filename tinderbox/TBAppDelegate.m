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

@implementation TBAppDelegate {
    TBNodeWindowController *_first;
}



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [TBNodeServer sharedServer];
    [NSURLProtocol registerClass:[TBNodeURLProtocol class]];
    [[NSNotificationCenter defaultCenter] addObserverForName:TBNodeServerDidStartNotification object:[TBNodeServer sharedServer] queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
        _first = [[TBNodeWindowController alloc] initWithWindowNibName:nil defaultURL:[NSURL URLWithString:@"http://tinderbox.local/main"]];
        [_first showWindow:self];
    }];
    
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[TBNodeServer sharedServer] stopServer];
}

@end
