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
+(BOOL) shouldSnapWindow:(RAWindowBar*)bar;
+(RAWindowSnapLocation) snapLocationForWindow:(RAWindowBar*)windowBar;
+(CGPoint) snapCenterForWindow:(RAWindowBar*)window toLocation:(RAWindowSnapLocation)location;
+(void) snapWindow:(RAWindowBar*)window toLocation:(RAWindowSnapLocation)location animated:(BOOL)animated;
+(void) snapWindow:(RAWindowBar*)window toLocation:(RAWindowSnapLocation)location animated:(BOOL)animated completion:(dispatch_block_t)completionBlock;
@end

RAWindowSnapLocation RAWindowSnapLocationGetLeftOfScreen();
RAWindowSnapLocation RAWindowSnapLocationGetRightOfScreen();
