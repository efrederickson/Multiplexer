#import "headers.h"
#import "RAAppSelectorView.h"

@interface RASwipeOverOverlay : UIAutoRotatingWindow <UIGestureRecognizerDelegate, UILongPressGestureRecognizerDelegate, RAAppSelectorViewDelegate> {
	BOOL isHidingUnderlyingApp;

	UIView *darkenerView;
}
@property (nonatomic, retain) UIView *grabberView;

-(BOOL) isHidingUnderlyingApp;
-(void) showEnoughToDarkenUnderlyingApp;
-(void) removeOverlayFromUnderlyingApp;
-(void) removeOverlayFromUnderlyingAppImmediately;

-(BOOL) isShowingAppSelector;
-(void) showAppSelector;

-(UIView*) currentView;
@end