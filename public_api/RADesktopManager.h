#import "RADesktopWindow.h"

@interface RADesktopManager : NSObject
+(instancetype) sharedInstance;

-(void) addDesktop:(BOOL)switchTo;
-(void) removeDesktopAtIndex:(NSUInteger)index;
-(void) removeAppWithIdentifier:(NSString*)bundleIdentifier animated:(BOOL)animated;
-(void) removeAppWithIdentifier:(NSString*)bundleIdentifier animated:(BOOL)animated forceImmediateUnload:(BOOL)force;

-(BOOL) isAppOpened:(NSString*)identifier;
-(RAWindowBar*) windowForIdentifier:(NSString*)identifier;

-(NSUInteger) currentDesktopIndex;
-(RADesktopWindow*) currentDesktop;

-(NSArray*) availableDesktops;
-(NSUInteger) numberOfDesktops;
-(RADesktopWindow*) desktopAtIndex:(NSUInteger)index;

-(void) switchToDesktop:(NSUInteger)index;
-(void) switchToDesktop:(NSUInteger)index actuallyShow:(BOOL)show;

-(void) hideDesktop;
-(void) reshowDesktop;
@end