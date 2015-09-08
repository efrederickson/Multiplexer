#import "RAIconBadgeView.h"
#import "headers.h"
#import <objc/runtime.h>

@implementation RAIconBadgeView
-(void) setText:(NSString*)text
{
	[super setText:text];

	//[self sizeToFit];
	//CGRect f = self.frame;
	//f.size.width += [objc_getClass("SBIconBadgeView") _textPadding];
	//f.size.height = f.size.width;
	//f.size.height = 24;
	//self.frame = f;

	//self.layer.cornerRadius = MAX(f.size.width, f.size.height) / 2;

	//UIImage *img = [objc_getClass("SBIconBadgeView") _createImageForText:text highlighted:NO];
	//self.backgroundColor = [UIColor colorWithPatternImage:img];
	//self.frame = (CGRect) { self.frame.origin, img.size };
}
@end