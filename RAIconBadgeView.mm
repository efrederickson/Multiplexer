#import "RAIconBadgeView.h"

@implementation RAIconBadgeView
-(void) setText:(NSString*)text
{
	[super setText:text];

	[self sizeToFit];
	CGRect f = self.frame;
	f.size.width += 10;
	f.size.height = 24;
	self.frame = f;

	self.layer.cornerRadius = f.size.height / 2;
}
@end