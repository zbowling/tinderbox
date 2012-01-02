//
//  NSString+TB.m
//  tinderbox
//
//  Created by Zac Bowling on 1/1/12.
//  Copyright (c) 2012 Zac Bowling. All rights reserved.
//

#import "NSString+TB.h"

@implementation NSString (TB)

#pragma mark - URL Escaping and Unescaping

- (NSString *)stringByEscapingForURLQuery {
	NSString *result = self;
    
	static CFStringRef leaveAlone = CFSTR(" ");
	static CFStringRef toEscape = CFSTR("\n\r:/=,!$&'()*+;[]@#?%");
    
	CFStringRef escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)self, leaveAlone,
																	 toEscape, kCFStringEncodingUTF8);
    
	if (escapedStr) {
		NSMutableString *mutable = [NSMutableString stringWithString:(__bridge NSString *)escapedStr];
		CFRelease(escapedStr);
        
		[mutable replaceOccurrencesOfString:@" " withString:@"+" options:0 range:NSMakeRange(0, [mutable length])];
		result = mutable;
	}
	return result;  
}


- (NSString *)stringByUnescapingFromURLQuery {
	NSString *deplussed = [self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    return [deplussed stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


#pragma mark - URL Encoding and Unencoding (Deprecated)

- (NSString *)URLEncodedString {
	static CFStringRef toEscape = CFSTR(":/=,!$&'()*+;[]@#?%");
	return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																(__bridge CFStringRef)self,
																NULL,
																toEscape,
																kCFStringEncodingUTF8);
}


- (NSString *)URLEncodedParameterString {
	static CFStringRef toEscape = CFSTR(":/=,!$&'()*+;[]@#?");
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (__bridge CFStringRef)self,
                                                                           NULL,
                                                                           toEscape,
                                                                           kCFStringEncodingUTF8);
}


- (NSString *)URLDecodedString {
	return (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
																				(__bridge CFStringRef)self,
																				CFSTR(""),
																				kCFStringEncodingUTF8);
}

@end
