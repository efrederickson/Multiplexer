#import "RAInsetLabel.h"

@implementation RAInsetLabel
- (void)drawTextInRect:(CGRect)rect 
{
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.textInset)];
}
@end