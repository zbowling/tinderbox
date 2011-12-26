//
//  TBTinderWindow.m
//  tinderbox
//
//  Created by Zac Bowling on 12/24/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import "TBTinderWindow.h"

@implementation TBTinderWindow
@synthesize webView=_webView;

- (id)init
{
    self = [super initWithWindowNibName:@"TinderWindow"];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL: [NSURL URLWithString:@"tinderbox://localhost/main"]]];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
