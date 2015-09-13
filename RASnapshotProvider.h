#import "RADesktopWindow.h"

@interface RASnapshotProvider : NSObject {
	NSCache *imageCache;
}
+(id) sharedInstance;

-(UIImage*) snapshotForDesktop:(RADesktopWindow*)desktop;
-(void) forceReloadSnapshotOfDesktop:(RADesktopWindow*)desktop;

-(UIImage*) storedSnapshotOfMissionControl;
-(void) storeSnapshotOfMissionControl:(UIWindow*)window;

-(UIImage*) snapshotForIdentifier:(NSString*)identifier;
-(void) forceReloadOfSnapshotForIdentifier:(NSString*)identifier;

-(UIImage*) wallpaperImage;

-(void) forceReloadEverything;
@end