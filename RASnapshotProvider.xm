#import "headers.h"
#import "RASnapshotProvider.h"
#import "RAWindowBar.h"

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

		if (app && app.mainSceneID)
		{
			CGRect frame = CGRectMake(0, 0, 0, 0);
			UIView *view = [%c(SBUIController) _zoomViewWithSplashboardLaunchImageForApplication:app sceneID:app.mainSceneID screen:UIScreen.mainScreen interfaceOrientation:0 includeStatusBar:YES snapshotFrame:&frame];

			if (view)
			{
				UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, YES, [UIScreen mainScreen].scale);
				CGContextRef c = UIGraphicsGetCurrentContext();
				//CGContextSetAllowsAntialiasing(c, YES);
				[view.layer performSelectorOnMainThread:@selector(renderInContext:) withObject:(__bridge id)c waitUntilDone:YES];
				image = UIGraphicsGetImageFromCurrentImageContext();
				UIGraphicsEndImageContext();
				view.layer.contents = nil;
			}
		}
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

-(UIImage*) storedSnapshotOfMissionControl
{
	return [imageCache objectForKey:@"missioncontrol"];
}

-(void) storeSnapshotOfMissionControl:(UIWindow*)window
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen]._interfaceOrientedBounds.size, YES, [UIScreen mainScreen].scale);
		CGContextRef c = UIGraphicsGetCurrentContext();
		//CGContextSetAllowsAntialiasing(c, YES);
		[window.layer performSelectorOnMainThread:@selector(renderInContext:) withObject:(__bridge id)c waitUntilDone:YES];
		UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		window.layer.contents = nil;

		if (image)
			[imageCache setObject:image forKey:@"missioncontrol"];
	});

}

-(NSString*) createKeyForDesktop:(RADesktopWindow*)desktop
{
	return [NSString stringWithFormat:@"desktop-%lu", (unsigned long)desktop.hash];
}

-(UIImage*) snapshotForDesktop:(RADesktopWindow*)desktop
{
	NSString *key = [self createKeyForDesktop:desktop];
	if ([imageCache objectForKey:key] != nil) return [imageCache objectForKey:key];

	UIImage *img = [self renderPreviewForDesktop:desktop];
	if (img)
		[imageCache setObject:img forKey:key];
	return img;
}

-(void) forceReloadSnapshotOfDesktop:(RADesktopWindow*)desktop
{
	[imageCache removeObjectForKey:[self createKeyForDesktop:desktop]];
}

-(UIImage*) renderPreviewForDesktop:(RADesktopWindow*)desktop
{
	UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen]._interfaceOrientedBounds.size, YES, [UIScreen mainScreen].scale);
	CGContextRef c = UIGraphicsGetCurrentContext();

	//[MSHookIvar<UIWindow*>([%c(SBWallpaperController) sharedInstance], "_wallpaperWindow").layer renderInContext:c]; // Wallpaper
	//[[[[%c(SBUIController) sharedInstance] window] layer] renderInContext:c]; // Icons
	//[desktop.layer renderInContext:c]; // Desktop windows

    [[%c(SBWallpaperController) sharedInstance] beginRequiringWithReason:@"BeautifulAnimation"];

	[MSHookIvar<UIWindow*>([%c(SBWallpaperController) sharedInstance], "_wallpaperWindow").layer performSelectorOnMainThread:@selector(renderInContext:) withObject:(__bridge id)c waitUntilDone:YES]; // Wallpaper
	[[[[%c(SBUIController) sharedInstance] window] layer] performSelectorOnMainThread:@selector(renderInContext:) withObject:(__bridge id)c waitUntilDone:YES]; // Icons
	[desktop.layer performSelectorOnMainThread:@selector(renderInContext:) withObject:(__bridge id)c waitUntilDone:YES]; // Desktop windows
	
	for (UIView *view in desktop.subviews) // Application views
	{
		if ([view isKindOfClass:[RAWindowBar class]])
		{
			RAHostedAppView *hostedView = [((RAWindowBar*)view) attachedView];

			UIImage *image = [RASnapshotProvider.sharedInstance snapshotForIdentifier:hostedView.bundleIdentifier];
			CIImage *coreImage = image.CIImage;
			if (!coreImage)
			    coreImage = [CIImage imageWithCGImage:image.CGImage];

			coreImage = [coreImage imageByApplyingTransform:CGAffineTransformInvert(view.transform)];
			image = [UIImage imageWithCIImage:coreImage];
			[image drawInRect:view.frame];

			//[image drawInRect:CGRectMake([hostedView convertPoint:hostedView.frame.origin toView:nil].x, [hostedView convertPoint:hostedView.frame.origin toView:nil].y, view.frame.size.width, view.frame.size.height)];
    		//CGContextConcatCTM(c, view.transform);

			/*SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:hostedView.bundleIdentifier];
			FBScene *scene = [app mainScene];
    		FBWindowContextHostManager *contextHostManager = [scene contextHostManager];
    		UIView *snapshotView = [contextHostManager snapshotViewWithFrame:hostedView.frame excludingContexts:@[] opaque:NO];
    		
			UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, YES, [UIScreen mainScreen].scale);
			CGContextRef c2 = UIGraphicsGetCurrentContext();
			//CGContextSetRGBFillColor(c2, 0, 0, 0, 0); // CGContextSetGrayFillColor
    		//snapshotView.layer.frame = (CGRect) { [desktop convertPoint:view.frame.origin toView:nil], view.frame.size };
    		//snapshotView.transform = view.transform;
    		[snapshotView.layer renderInContext:c2];
    		UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    		UIGraphicsEndImageContext();

    		// TODO: needs to be improved, no status bar + it's slightly off
			//CGContextDrawImage(c, CGRectMake(view.frame.origin.x + hostedView.frame.origin.x, view.frame.origin.y + hostedView.frame.origin.y, hostedView.frame.size.width, hostedView.frame.size.height), image.CGImage);
			[image drawInRect:CGRectMake(view.frame.origin.x, [hostedView convertPoint:hostedView.frame.origin toView:nil].y, view.frame.size.width, view.frame.size.height)];
			*/
		}
	}
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	MSHookIvar<UIWindow*>([%c(SBWallpaperController) sharedInstance], "_wallpaperWindow").layer.contents = nil;
	[[[%c(SBUIController) sharedInstance] window] layer].contents = nil;
	desktop.layer.contents = nil;
	return image;
}
@end