//
//  UIColor+HexString.m
//
//  Created by Micah Hainline
//  http://stackoverflow.com/users/590840/micah-hainline
//

#import "UIColor+HexString.h"


@implementation UIColor (HexString)

+ (CGFloat) RA_colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString:fullHex] scanHexInt:&hexComponent];
    return hexComponent / 255.0;
}

+ (UIColor *) RA_colorWithHexString: (NSString *) hexString {
    if (hexString.length == 0)
        return nil;
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self RA_colorComponentFrom: colorString start: 0 length: 1];
            green = [self RA_colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self RA_colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self RA_colorComponentFrom: colorString start: 0 length: 1];
            red   = [self RA_colorComponentFrom: colorString start: 1 length: 1];
            green = [self RA_colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self RA_colorComponentFrom: colorString start: 3 length: 1];          
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self RA_colorComponentFrom: colorString start: 0 length: 2];
            green = [self RA_colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self RA_colorComponentFrom: colorString start: 4 length: 2];                      
            break;
        case 8: // #AARRGGBB
            alpha = [self RA_colorComponentFrom: colorString start: 0 length: 2];
            red   = [self RA_colorComponentFrom: colorString start: 2 length: 2];
            green = [self RA_colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self RA_colorComponentFrom: colorString start: 6 length: 2];                      
            break;
        default:
            return nil;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

@end
