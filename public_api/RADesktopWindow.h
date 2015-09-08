#import "RAHostedAppView.h"

@class RAWindowBar;

@interface RADesktopWindow : UIWindow
-(RAWindowBar*) addAppWithView:(RAHostedAppView*)view animated:(BOOL)animated;
-(RAWindowBar*) createAppWindowForSBApplication:(SBApplication*)app animated:(BOOL)animated;
-(RAWindowBar*) createAppWindowWithIdentifier:(NSString*)identifier animated:(BOOL)animated;

-(void) removeAppWithIdentifier:(NSString*)identifier animated:(BOOL)animated;
-(void) removeAppWithIdentifier:(NSString*)identifier animated:(BOOL)animated forceImmediateUnload:(BOOL)force;

-(NSArray*) hostedWindows;
-(BOOL) isAppOpened:(NSString*)identifier;
-(RAWindowBar*) windowForIdentifier:(NSString*)identifier;

-(void) unloadApps;
-(void) loadApps;
-(void) closeAllApps;
@end