//
//  TBWebViewPreferencesScriptableObject.m
//  tinderbox
//
//  Created by Zac Bowling on 12/26/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBWebViewPreferencesScriptableObject.h"

@implementation TBWebViewPreferencesScriptableObject

+(id)sharedObject {
    static TBWebViewPreferencesScriptableObject *sharedObject;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [[TBWebViewPreferencesScriptableObject alloc] init];
    });
    return sharedObject;
}

- (id)get:(NSString*)key {
    if (!key) 
        return nil;

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];    
    
    id value = [defaults stringForKey:key];
    if (value == nil) {
        return nil;
    }
    return value;
}

//backwords for javascript 
-(void)setKey:(NSString*)key withValue:(id)value {
    if (!key) 
        return;
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];    
    
    if (value)
        [defaults setValue:value forKey:key];
    else 
        [defaults removeObjectForKey:key];
    
    [defaults synchronize];
}

+ (NSString *)webScriptNameForSelector:(SEL)selector {
    if (selector == @selector(get:)) {
        return @"get";
    }
    
    if (selector == @selector(setKey:withValue:) ){
        return @"set";
    }
    
    return nil;
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
    if (selector == @selector(get:) || selector == @selector(setKey:withValue:) ) {
        return NO;
    }
    return YES;
}

@end
