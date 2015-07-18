#import "headers.h"
#import "RADesktopWindow.h"
#import "RAWindowBar.h"

struct RAPreservedWindowInformation {
	CGPoint center;
	CGAffineTransform transform;
};

struct RAPreservedDesktopInformation {
	NSUInteger index;
	NSArray *openApps; //NSArray<NSString>
};

@interface RAWindowStatePreservationSystemManager : NSObject {
	NSMutableDictionary *dict;
}
+(id) sharedInstance;

-(void) loadInfo;
-(void) saveInfo;

// Desktop
-(void) saveDesktopInformation:(RADesktopWindow*)desktop;
-(BOOL) hasDesktopInformationAtIndex:(NSInteger)index;
-(RAPreservedDesktopInformation) desktopInformationForIndex:(NSInteger)index;

// Window
-(void) saveWindowInformation:(RAWindowBar*)window;
-(BOOL) hasWindowInformationForIdentifier:(NSString*)appIdentifier;
-(RAPreservedWindowInformation) windowInformationForAppIdentifier:(NSString*)identifier;
@end