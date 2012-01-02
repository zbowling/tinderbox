//
//  NSDictionary+TB.h
//  tinderbox
//
//  Created by Zac Bowling on 1/1/12.
//  Copyright (c) 2012 Zac Bowling. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (TB)

+ (NSDictionary *)dictionaryWithFormEncodedString:(NSString *)encodedString;

@end
