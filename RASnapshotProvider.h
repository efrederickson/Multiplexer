#import "RADesktopWindow.h"

@interface RASnapshotProvider : NSObject {
	NSCache *imageCache;
}
+(id) sharedInstance;

-(UIImage*) snapshotForDesktop:(RADesktopWindow*)desktop;
-(void) forceReloadSnapshotOfDesktop:(RADesktopWindow*)desktop;

-(UIImage*) snapshotForIdentifier:(NSString*)identifier;
-(void) forceReloadOfSnapshotForIdentifier:(NSString*)identifier;
@end