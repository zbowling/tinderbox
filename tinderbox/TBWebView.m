//
//  TBWebView.m
//  tinderbox
//
//  Created by Zac Bowling on 12/26/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBWebView.h"
#import "TBWebViewPreferencesScriptableObject.h"

@implementation TBWebView

- (id)initWithFrame:(NSRect)frame frameName:(NSString *)frameName groupName:(NSString *)groupName {
    self = [super initWithFrame:frame frameName:frameName groupName:groupName];
    if (self)
    {
        [self setFrameLoadDelegate:self];
    }
    return self;
}


- (void)awakeFromNib {
    [self setFrameLoadDelegate:self];
}

- (void)setupWebScriptableObjects {
    // Create window.preferences object.
    [[self windowScriptObject] setValue:[TBWebViewPreferencesScriptableObject sharedObject] forKey:@"preferences"];
}

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame {
    [self setupWebScriptableObjects];
}


@end
