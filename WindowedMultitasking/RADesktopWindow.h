#import "RAHostedAppView.h"

@class RAWindowBar;

@interface RADesktopWindow : UIWindow {
	UIInterfaceOrientation lastKnownOrientation;
	NSMutableArray *appViews;

	BOOL dontClearForcedPhoneState;
}

-(RAWindowBar*) addAppWithView:(RAHostedAppView*)view animated:(BOOL)animated;
-(RAWindowBar*) createAppWindowForSBApplication:(SBApplication*)app animated:(BOOL)animated;
-(RAWindowBar*) createAppWindowWithIdentifier:(NSString*)identifier animated:(BOOL)animated;

-(void) addExistingWindow:(RAWindowBar*)window;
-(void) removeAppWithIdentifier:(NSString*)identifier animated:(BOOL)animated;
-(void) removeAppWithIdentifier:(NSString*)identifier animated:(BOOL)animated forceImmediateUnload:(BOOL)force;

-(NSArray*) hostedWindows;
-(BOOL) isAppOpened:(NSString*)identifier;

-(UIInterfaceOrientation) currentOrientation;
-(CGFloat) baseRotationForOrientation;
-(UIInterfaceOrientation) appOrientationRelativeToThisOrientation:(CGFloat)currentRotation;
-(void) updateRotationOnClients:(UIInterfaceOrientation)orientation;

-(void) updateWindowSizeForApplication:(NSString*)identifier;

-(void) unloadApps;
-(void) loadApps;
-(void) closeAllApps;

-(void) saveInfo;
-(void) loadInfo;
-(void) loadInfo:(NSInteger)index;
@end