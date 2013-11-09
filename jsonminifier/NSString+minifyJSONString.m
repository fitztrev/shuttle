//
//  NSString+minifyJSONString.m
//  jsonminifier
//
//  Created by Bödecs Tibor on 7/19/13.
//  Copyright (c) 2013 Bödecs Tibor. All rights reserved.
//

#import "NSString+minifyJSONString.h"

@implementation NSString (minifyJSONString)


- (NSString *)minifyJSONString
{
	BOOL in_string = NO;
	BOOL in_multiline_comment = NO;
	BOOL in_singleline_comment = NO;
	NSString *tmp;
    NSString *tmp2;
    NSMutableArray *new_str = [@[] mutableCopy];
    int from = 0;
    NSString *lc;
    NSString *rc;
    int lastIndex = 0;

    NSRegularExpression *tokenizer = [NSRegularExpression regularExpressionWithPattern:@"\"|(\\/\\*)|(\\*\\/)|(\\/\\/)|\n|\r"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
    NSRegularExpression *magic = [NSRegularExpression regularExpressionWithPattern:@"(\\\\)*$"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    
    NSArray *matches = [tokenizer matchesInString:self
                                          options:0
                                            range:NSMakeRange(0, self.length)];
    if ([matches count] == 0) {
        return self;
    }
    
    for (NSTextCheckingResult *match in matches) {
        NSRange range   = [match range];
        tmp             = [self substringWithRange:range];
        lastIndex       = (int)range.location + (int)range.length;
        lc              = [self substringWithRange:NSMakeRange(0, lastIndex - (int)range.length)];
        rc              = [self substringWithRange:NSMakeRange(lastIndex, self.length - lastIndex)];
        
        if ( !in_multiline_comment && !in_singleline_comment ) {
            tmp2 = [lc substringWithRange:NSMakeRange(from, lc.length - from)];
            if ( !in_string ) {
                NSArray* words = [tmp2 componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                tmp2 = [words componentsJoinedByString:@""];
            }
            [new_str addObject:tmp2];
        }
        from = lastIndex;
        
        if ( [tmp hasPrefix:@"\""] && !in_multiline_comment && !in_singleline_comment) {
            NSArray *_matches = [magic matchesInString:lc
                                               options:0
                                                 range:NSMakeRange(0, lc.length)];
            
            if (_matches.count > 0 ) {
                NSTextCheckingResult *_match = _matches[0];
                NSRange _range               = [_match range];
                
                if ( !in_string || _range.length%2 == 0 ) {
                    in_string = !in_string;
                }
            }
            from--;
            rc =  [self substringWithRange:NSMakeRange(from, self.length - from)];
        }
        else if ( [tmp hasPrefix:@"/*"] && !in_string && !in_multiline_comment && !in_singleline_comment ) {
            in_multiline_comment = YES;
        }
        else if ( [tmp hasPrefix:@"*/"] && !in_string && in_multiline_comment && !in_singleline_comment ) {
            in_multiline_comment = NO;
        }
        else if ( [tmp hasPrefix:@"//"] && !in_string && !in_multiline_comment && !in_singleline_comment) {
            in_singleline_comment = YES;
        }
        else if ( ([tmp hasPrefix:@"\n"] || [tmp hasPrefix:@"\r"]) && !in_string && !in_multiline_comment && in_singleline_comment) {
            in_singleline_comment = NO;
        }
        else if (!in_multiline_comment && !in_singleline_comment ) {
            NSArray* words = [tmp componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            tmp = [words componentsJoinedByString:@""];
            if (tmp && tmp.length) {
                [new_str addObject:tmp];
            }
        }
        
    }
    [new_str addObject:rc];
    
	return [new_str componentsJoinedByString:@""];
}

@end
