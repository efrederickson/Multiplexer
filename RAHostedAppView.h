#import "headers.h"

@class RAAppSliderProvider;

@interface RAHostedAppView : UIView {
	SBApplication *app;
	FBWindowContextHostWrapperView *view;
}
-(id) initWithBundleIdentifier:(NSString*)bundleIdentifier;

@property (nonatomic) BOOL showSplashscreenInsteadOfSpinner;

@property (nonatomic, retain) NSString *bundleIdentifier;
@property (nonatomic) BOOL autosizesApp;

@property (nonatomic) BOOL allowHidingStatusBar;
@property (nonatomic) BOOL hideStatusBar;

@property (nonatomic) BOOL shouldUseExternalKeyboard;

@property (nonatomic) BOOL isCurrentlyHosting;

-(SBApplication*) app;
-(NSString*) displayName;

@property (nonatomic, readonly) UIInterfaceOrientation orientation;
-(void) rotateToOrientation:(UIInterfaceOrientation)o;

-(void) preloadApp;
-(void) loadApp;
-(void) unloadApp;
-(void) unloadApp:(BOOL)forceImmediate;

@end