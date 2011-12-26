//
//  WebInspector.h
//  tinderbox
//
//  Created by Zac Bowling on 12/26/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//undocumented interface in WebKit
@interface WebInspector : NSObject
{
    WebView *_webView;
}
- (id)initWithWebView:(WebView *)webView;
- (void)detach:(id)sender;
- (void)show:(id)sender;
- (void)showConsole:(id)sender;
@end

