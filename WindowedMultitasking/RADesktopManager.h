#import "RADesktopWindow.h"

@interface RADesktopManager : NSObject {
	NSMutableArray *windows;
	RADesktopWindow *currentDesktop;
	NSUInteger currentDesktopIndex;
}
+(instancetype) sharedInstance;

-(void) addDesktop:(BOOL)switchTo;
-(void) removeDesktopAtIndex:(NSUInteger)index;
-(void) removeAppWithIdentifier:(NSString*)bundleIdentifier animated:(BOOL)animated;

-(BOOL) isAppOpened:(NSString*)identifier;

-(NSUInteger) currentDesktopIndex;
-(NSUInteger) numberOfDesktops;
-(void) switchToDesktop:(NSUInteger)index;
-(void) switchToDesktop:(NSUInteger)index actuallyShow:(BOOL)show;
-(RADesktopWindow*) currentDesktop;
-(NSArray*) availableDesktops;
-(RADesktopWindow*) desktopAtIndex:(NSUInteger)index;

-(void) updateRotationOnClients:(UIInterfaceOrientation)orientation;

-(void) hideDesktop;
-(void) reshowDesktop;
@end