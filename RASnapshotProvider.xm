#import "headers.h"
#import "RASnapshotProvider.h"

@implementation RASnapshotProvider
+(id) sharedInstance
{
	SHARED_INSTANCE2(RASnapshotProvider, sharedInstance->imageCache = [NSCache new]);
}

-(UIImage*) snapshotForIdentifier:(NSString*)identifier
{
	if ([imageCache objectForKey:identifier] != nil) return [imageCache objectForKey:identifier];
	
	UIImage *image = nil;

	SBDisplayItem *item = [%c(SBDisplayItem) displayItemWithType:@"App" displayIdentifier:identifier];
	NSObject *view = [[[%c(SBUIController) sharedInstance] switcherController] performSelector:@selector(_snapshotViewForDisplayItem:) withObject:item];
	if (view)
	{
		[view performSelector:@selector(_loadSnapshotSync)];
		image = MSHookIvar<UIImageView*>(view, "_snapshotImageView").image;	
	}

	if (!image)
	{
		SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier];

		CGRect frame;
		UIView *view = [%c(SBUIController) _zoomViewWithSplashboardLaunchImageForApplication:app sceneID:app.mainSceneID screen:UIScreen.mainScreen interfaceOrientation:0 includeStatusBar:YES snapshotFrame:&frame];

		UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, YES, [UIScreen mainScreen].scale);
		CGContextRef c = UIGraphicsGetCurrentContext();
		//CGContextSetAllowsAntialiasing(c, YES);
		[view.layer renderInContext:c];
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();

		if (!image) // we can only hope it does not reach this point of desperation
			image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Default.png", app.path]];
	}

	if (image)
	{
		[imageCache setObject:image forKey:identifier];
	}

	return image;
}

-(void) forceReloadOfSnapshotForIdentifier:(NSString*)identifier
{
	[imageCache removeObjectForKey:identifier];
}
@end