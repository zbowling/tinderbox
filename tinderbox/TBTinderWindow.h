//
//  TBTinderWindow.h
//  tinderbox
//
//  Created by Zac Bowling on 12/24/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface TBTinderWindow : NSWindowController 

@property (weak) IBOutlet WebView *webView;

- (IBAction)showConsole:(id)sender;
- (IBAction)hideConsole:(id)sender;

@end
