#import "RADesktopWindow.h"

@interface RADesktopManager : NSObject {
	NSMutableArray *windows;
	RADesktopWindow *currentDesktop;
	NSUInteger currentDesktopIndex;
}
+(instancetype) sharedInstance;

@property (nonatomic, weak) RAWindowBar *lastUsedWindow;

-(void) addDesktop:(BOOL)switchTo;
-(void) removeDesktopAtIndex:(NSUInteger)index;
-(void) removeAppWithIdentifier:(NSString*)bundleIdentifier animated:(BOOL)animated;
-(void) removeAppWithIdentifier:(NSString*)bundleIdentifier animated:(BOOL)animated forceImmediateUnload:(BOOL)force;

-(BOOL) isAppOpened:(NSString*)identifier;
-(RAWindowBar*) windowForIdentifier:(NSString*)identifier;

-(NSUInteger) currentDesktopIndex;
-(NSUInteger) numberOfDesktops;
-(void) switchToDesktop:(NSUInteger)index;
-(void) switchToDesktop:(NSUInteger)index actuallyShow:(BOOL)show;
-(RADesktopWindow*) currentDesktop;
-(NSArray*) availableDesktops;
-(RADesktopWindow*) desktopAtIndex:(NSUInteger)index;

-(void) updateWindowSizeForApplication:(NSString*)identifier;
-(void) updateRotationOnClients:(UIInterfaceOrientation)orientation;

-(void) hideDesktop;
-(void) reshowDesktop;

-(void) findNewForemostApp;
@end