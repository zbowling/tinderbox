//
//  TBTinderWindow.m
//  tinderbox
//
//  Created by Zac Bowling on 12/24/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBNodeWindowController.h"
#import "WebInspector.h"
#import "TBWebView.h"
#import "TBWebViewPreferencesScriptableObject.h"
#import "TBWebViewAppScriptableObject.h"


@implementation TBNodeWindowController {
    WebInspector *_webInspector;
    NSURL *_defaultURL;
}
@synthesize webView=_webView;

- (id)initWithWindowNibName:(NSString *)windowNibNameOrNil defaultURL:(NSURL *)defaultURL
{
    if (!windowNibNameOrNil)
        windowNibNameOrNil = @"BasicWebWindow";
    
    self = [super initWithWindowNibName:windowNibNameOrNil];
    if (self) {
        _defaultURL = defaultURL;
    }
    
    return self;
}

- (IBAction)showConsole:(id)sender {
    if(!_webInspector) {
        _webInspector = [[WebInspector alloc] initWithWebView:self.webView];
        [_webInspector detach:self.webView];
    }
    
    [_webInspector showConsole:self.webView];
}


- (IBAction)hideConsole:(id)sender {
    if(!_webInspector) {
        _webInspector = [[WebInspector alloc] initWithWebView:self.webView];
        [_webInspector detach:self.webView];
    }
    
    [_webInspector show:self.webView];
}


- (void)windowDidLoad
{
    [super windowDidLoad];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:_defaultURL]];
        [[self webView] setFrameLoadDelegate:self];
    });
    [self becomeFirstResponder];

}

- (void)setupWebScriptableObjects {
    // Create window.preferences object.
    [[self.webView windowScriptObject] setValue:[TBWebViewPreferencesScriptableObject sharedObject] forKey:@"preferences"];
    [[self.webView windowScriptObject] setValue:[TBWebViewAppScriptableObject sharedObject] forKey:@"tinderbox"];
}

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame {
    [self setupWebScriptableObjects];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    NSLog(@"did fail to load with error: %@",error);
}

- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource {
    NSLog(@"did fail to load with error: %@",error);
}


@end
