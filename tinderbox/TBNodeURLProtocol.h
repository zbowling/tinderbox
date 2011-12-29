//
//  TBURLProtocol.h
//  tinderbox
//
//  Created by Zac Bowling on 12/25/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TBNodeURLProtocol : NSURLProtocol<NSStreamDelegate>

+ (NSString *)protocolScheme;

@end
