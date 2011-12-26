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
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL: [NSURL URLWithString:@"tinderbox:///main"]]];
    });

    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
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
