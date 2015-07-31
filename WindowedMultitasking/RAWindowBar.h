#import "headers.h"
#import "RAHostedAppView.h"

@class RADesktopWindow;

@interface RAWindowBar : UIView<UIGestureRecognizerDelegate, UILongPressGestureRecognizerDelegate> {
	RAHostedAppView *attachedView;
}

@property (nonatomic, weak) RADesktopWindow *desktop;

-(void) close;
-(void) maximize;
-(void) minimize;

-(void) showOverlay;
-(void) hideOverlay;
-(BOOL) isOverlayShowing;

-(RAHostedAppView*) attachedView;
-(void) attachView:(RAHostedAppView*)view;

-(void) scaleTo:(CGFloat)scale animated:(BOOL)animate;

-(void) saveWindowInfo;
@end