#import "headers.h"
#import "RARunningAppsProvider.h"

@class RAAppSliderProvider;

@interface RAHostedAppView : UIView <RARunningAppsProviderDelegate> {
	SBApplication *app;
	FBWindowContextHostWrapperView *view;
}

+(void) iPad_iOS83_fixHosting;

-(id) initWithBundleIdentifier:(NSString*)bundleIdentifier;

@property (nonatomic) BOOL showSplashscreenInsteadOfSpinner;
@property (nonatomic) BOOL renderWallpaper;

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