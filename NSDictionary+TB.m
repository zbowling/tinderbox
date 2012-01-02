//
//  NSDictionary+TB.m
//  tinderbox
//
//  Created by Zac Bowling on 1/1/12.
//  Copyright (c) 2012 Zac Bowling. All rights reserved.
//

#import "NSDictionary+TB.h"
#import "NSString+TB.h"

@implementation NSDictionary (TB)

+ (NSDictionary *)dictionaryWithFormEncodedString:(NSString *)encodedString {
	if (!encodedString) {
		return nil;
	}
    
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	NSArray *pairs = [encodedString componentsSeparatedByString:@"&"];
    
	for (NSString *kvp in pairs) {
		if ([kvp length] == 0) {
			continue;
		}
        
		NSRange pos = [kvp rangeOfString:@"="];
		NSString *key;
		NSString *val;
        
		if (pos.location == NSNotFound) {
			key = [kvp stringByUnescapingFromURLQuery];
			val = @"";
		} else {
			key = [[kvp substringToIndex:pos.location] stringByUnescapingFromURLQuery];
			val = [[kvp substringFromIndex:pos.location + pos.length] stringByUnescapingFromURLQuery];
		}
        
		if (!key || !val) {
			continue; // I'm sure this will bite my arse one day
		}
        
		[result setObject:val forKey:key];
	}
	return result;
}

@end
