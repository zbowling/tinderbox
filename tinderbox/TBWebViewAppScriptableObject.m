//
//  TBWebViewAppScriptableObject.m
//  tinderbox
//
//  Created by Zac Bowling on 12/27/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBWebViewAppScriptableObject.h"
#import "TBAppDelegate.h"
@implementation TBWebViewAppScriptableObject

+(id)sharedObject {
    static TBWebViewAppScriptableObject *sharedObject;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [[TBWebViewAppScriptableObject alloc] init];
    });
    return sharedObject;
}

- (void) showRoomWindowWithRoomID:(id)roomId {
    [[NSApp delegate] showRoomWindowWithRoomID:[roomId stringValue]];
}


+ (NSString *)webScriptNameForSelector:(SEL)selector {
    if (selector == @selector(showRoomWindowWithRoomID:)) {
        return @"showRoomWindow";
    }
    
    return nil;
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
    if (selector == @selector(showRoomWindowWithRoomID:)) {
        return NO;
    }
    return YES;
}

@end
