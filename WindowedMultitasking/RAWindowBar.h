#import "headers.h"
#import "RAHostedAppView.h"

@interface RAWindowBar : UIView<UIGestureRecognizerDelegate, UILongPressGestureRecognizerDelegate> {
	RAHostedAppView *attachedView;
}

-(RAHostedAppView*) attachedView;
-(void) attachView:(RAHostedAppView*)view;
@end