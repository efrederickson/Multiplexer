#import "RAHostedAppView.h"

@class RADesktopWindow;

@interface RAWindowBar : UIView
@property (nonatomic, weak) RADesktopWindow *desktop;

-(void) close;
-(void) maximize;
-(void) minimize;
-(BOOL) isLocked;

-(void) showOverlay;
-(void) hideOverlay;
-(BOOL) isOverlayShowing;

-(RAHostedAppView*) attachedView;
-(void) attachView:(RAHostedAppView*)view;

-(void) scaleTo:(CGFloat)scale animated:(BOOL)animate;
@end