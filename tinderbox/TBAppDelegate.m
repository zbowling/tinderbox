//
//  TBAppDelegate.m
//  tinderbox
//
//  Created by Zac Bowling on 12/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TBAppDelegate.h"
#import "TBNodeServer.h"

@implementation TBAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [TBNodeServer sharedServer];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[TBNodeServer sharedServer] stopServer];
}

@end
