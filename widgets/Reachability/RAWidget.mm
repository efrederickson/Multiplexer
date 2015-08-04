#import "RAWidget.h"

@implementation RAWidget

-(NSString*)identifier
{
	@throw @"This is an abstract method and must be overriden";
}

-(UIView*) view
{
	@throw @"This is an abstract method and must be overriden";
}

-(UIView*) iconForSize:(CGSize)size
{
	@throw @"This is an abstract method and must be overriden";
}

-(CGFloat) preferredHeight
{
	return self.view.frame.size.height;
}
@end