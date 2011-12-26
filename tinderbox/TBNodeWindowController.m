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
    self.webView.frameLoadDelegate = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:_defaultURL]];
    });
    [self becomeFirstResponder];

}

- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource {
    NSLog(@"fail to load %@",error);
}

- (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource {
    NSLog(@"didFinishLoadingFromDataSource %@",identifier);
}

- (void)webView:(WebView *)sender resource:(id)identifier didReceiveContentLength:(NSUInteger)length fromDataSource:(WebDataSource *)dataSource {
    NSLog(@"didReceiveContentLength %lu",length);
}


@end
