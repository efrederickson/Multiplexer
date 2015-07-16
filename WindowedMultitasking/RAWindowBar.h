#import "headers.h"
#import "RAHostedAppView.h"

@interface RAWindowBar : UIView<UIGestureRecognizerDelegate, UILongPressGestureRecognizerDelegate> {
	RAHostedAppView *attachedView;
}

-(void) close;
-(void) maximize;
-(void) minimize;

-(void) showOverlay;
-(void) hideOverlay;
-(BOOL) isOverlayShowing;

-(RAHostedAppView*) attachedView;
-(void) attachView:(RAHostedAppView*)view;
@end