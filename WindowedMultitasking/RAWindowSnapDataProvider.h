#import "RAWindowBar.h"
#import "RADesktopWindow.h"

enum RAWindowSnapLocation {
	RAWindowSnapLocationInvalid = 0,

	RAWindowSnapLocationLeftTop,
	RAWindowSnapLocationLeftMiddle,
	RAWindowSnapLocationLeftBottom,
	
	RAWindowSnapLocationRightTop,
	RAWindowSnapLocationRightMiddle,
	RAWindowSnapLocationRightBottom,

	RAWindowSnapLocationBottom,
	RAWindowSnapLocationTop,
	RAWindowSnapLocationBottomCenter,

	RAWindowSnapLocationBottomLeft = RAWindowSnapLocationLeftBottom,
	RAWindowSnapLocationBottomRight = RAWindowSnapLocationRightBottom,

	RAWindowSnapLocationRight = RAWindowSnapLocationRightMiddle,
	RAWindowSnapLocationLeft = RAWindowSnapLocationLeftMiddle,
	RAWindowSnapLocationNone = RAWindowSnapLocationInvalid,
};

@interface RAWindowSnapDataProvider : NSObject
+(BOOL) shouldSnapWindowAtLocation:(CGRect)location;
+(RAWindowSnapLocation) snapLocationForWindowLocation:(CGRect)location;
+(void) snapWindow:(RAWindowBar*)window toLocation:(RAWindowSnapLocation)location animated:(BOOL)animated;
@end