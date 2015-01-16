#import "RAWidget.h"

@implementation RAWidget

-(NSString*)identifier
{
	@throw @"This is an abstract method and must be overriden";
}

-(UIView*) view
{
	return nil;
}

-(UIView*) iconForSize:(CGSize)size
{
	return nil; 
}
@end