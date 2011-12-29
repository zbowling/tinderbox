//
//  TBTinderWindow.h
//  tinderbox
//
//  Created by Zac Bowling on 12/24/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class TBWebView;
@interface TBNodeWindowController : NSWindowController 

- (id)initWithWindowNibName:(NSString *)windowNibNameOrNil defaultURL:(NSURL *)defaultURL;

@property (weak) IBOutlet TBWebView *webView;

- (void)setupWebScriptableObjects;

@end
