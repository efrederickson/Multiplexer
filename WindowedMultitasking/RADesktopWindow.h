#import "RAHostedAppView.h"

@class RAWindowBar;

@interface RADesktopWindow : UIWindow {
	NSMutableArray *appViews;
}

-(RAWindowBar*) addAppWithView:(RAHostedAppView*)view animated:(BOOL)animated;
-(RAWindowBar*) createAppWindowForSBApplication:(SBApplication*)app animated:(BOOL)animated;
-(RAWindowBar*) createAppWindowWithIdentifier:(NSString*)identifier animated:(BOOL)animated;

-(void) addExistingWindow:(RAWindowBar*)window;
-(void) removeAppWithIdentifier:(NSString*)identifier animated:(BOOL)animated;

-(NSArray*) hostedWindows;

-(void) unloadApps;
-(void) loadApps;
-(void) closeAllApps;
@end