//
//  TBNodeCallbackRequest.h
//  tinderbox
//
//  Created by Zac Bowling on 12/30/11.
//  Copyright (c) 2011 Zac Bowling. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TBSocketConnection;

@interface TBSocketRequest : NSObject

- (id)initWithHTTPMessage:(CFHTTPMessageRef)requestRef;

@property (nonatomic, readonly) CFHTTPMessageRef requestHTTPMessage;
@property (nonatomic, readonly) NSString *HTTPMethod;
@property (nonatomic, readonly) NSString *HTTPVersion;
@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic, readonly) NSDictionary *allHTTPHeaderFields;
@property (nonatomic, readonly) NSData *HTTPBody;

@end
