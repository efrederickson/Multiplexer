#import "RAHostedAppView.h"

@interface RADesktopWindow : UIWindow {
	NSMutableArray *appViews;
}

-(void) addAppWithView:(RAHostedAppView*)view animated:(BOOL)animated;
-(void) createAppWindowForSBApplication:(SBApplication*)app animated:(BOOL)animated;
-(void) createAppWindowWithIdentifier:(NSString*)identifier animated:(BOOL)animated;

-(void) removeAppWithIdentifier:(NSString*)identifier animated:(BOOL)animated;

-(NSArray*) hostedWindows;

-(void) unloadApps;
-(void) loadApps;
-(void) closeAllApps;
@end