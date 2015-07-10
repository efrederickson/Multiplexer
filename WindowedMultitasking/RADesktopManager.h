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

-(NSUInteger) currentDesktopIndex;
-(NSUInteger) numberOfDesktops;
-(void) switchToDesktop:(NSUInteger)index;
-(RADesktopWindow*) currentDesktop;
-(NSArray*) availableDesktops;
-(RADesktopWindow*) desktopAtIndex:(NSUInteger)index;

-(void) hideDesktop;
-(void) reshowDesktop;
@end