#import "headers.h"
#import "RASnapshotProvider.h"
#import "RAWindowBar.h"

@implementation RASnapshotProvider
+(id) sharedInstance
{
	SHARED_INSTANCE2(RASnapshotProvider, sharedInstance->imageCache = [NSCache new]);
}

-(UIImage*) snapshotForIdentifier:(NSString*)identifier orientation:(UIInterfaceOrientation)orientation
{
	if ([imageCache objectForKey:identifier] != nil) return [imageCache objectForKey:identifier];
	
	UIImage *image = nil;

	SBDisplayItem *item = [%c(SBDisplayItem) displayItemWithType:@"App" displayIdentifier:identifier];
	SBAppSwitcherSnapshotView *view = [[[%c(SBUIController) sharedInstance] switcherController] performSelector:@selector(_snapshotViewForDisplayItem:) withObject:item];
	[view setOrientation:orientation orientationBehavior:0];
	if (view)
	{
		[view _loadSnapshotSync];
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

-(UIImage*) snapshotForIdentifier:(NSString*)identifier
{
	return [self snapshotForIdentifier:identifier orientation:UIApplication.sharedApplication.statusBarOrientation];
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

- (UIImage*)rotateImageToMatchOrientation:(UIImage*)oldImage
{
	CGFloat degrees = 0;
	if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight)
		degrees = 270;
	else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
		degrees = 90;
	else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)
		degrees = 180;

	// https://stackoverflow.com/questions/20764623/rotate-newly-created-ios-image-90-degrees-prior-to-saving-as-png

	//Calculate the size of the rotated view's containing box for our drawing space
	static UIView *rotatedViewBox = [[UIView alloc] init];
	rotatedViewBox.frame = CGRectMake(0,0,oldImage.size.width, oldImage.size.height);
	CGAffineTransform t = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(degrees));
	rotatedViewBox.transform = t;

	CGSize rotatedSize = rotatedViewBox.frame.size;
	//CGSize rotatedSize = CGSizeApplyAffineTransform(oldImage.size, CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(degrees)));

	//Create the bitmap context
	UIGraphicsBeginImageContext(rotatedSize);
	CGContextRef bitmap = UIGraphicsGetCurrentContext();

	//Move the origin to the middle of the image so we will rotate and scale around the center.
	CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);

	//Rotate the image context
	CGContextRotateCTM(bitmap, (degrees * M_PI / 180));

	//Now, draw the rotated/scaled image into the context
	CGContextScaleCTM(bitmap, 1.0, -1.0);
	CGContextDrawImage(bitmap, CGRectMake(-oldImage.size.width / 2, -oldImage.size.height / 2, oldImage.size.width, oldImage.size.height), [oldImage CGImage]);

	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

-(UIImage*) renderPreviewForDesktop:(RADesktopWindow*)desktop
{
	UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, YES, [UIScreen mainScreen].scale);
	CGContextRef c = UIGraphicsGetCurrentContext();

	//[MSHookIvar<UIWindow*>([%c(SBWallpaperController) sharedInstance], "_wallpaperWindow").layer renderInContext:c]; // Wallpaper
	//[[[[%c(SBUIController) sharedInstance] window] layer] renderInContext:c]; // Icons
	//[desktop.layer renderInContext:c]; // Desktop windows

    [[%c(SBWallpaperController) sharedInstance] beginRequiringWithReason:@"BeautifulAnimation"];
    [[%c(SBUIController) sharedInstance] restoreContentAndUnscatterIconsAnimated:NO];

	[MSHookIvar<UIWindow*>([%c(SBWallpaperController) sharedInstance], "_wallpaperWindow").layer performSelectorOnMainThread:@selector(renderInContext:) withObject:(__bridge id)c waitUntilDone:YES]; // Wallpaper
	[[[[%c(SBUIController) sharedInstance] window] layer] performSelectorOnMainThread:@selector(renderInContext:) withObject:(__bridge id)c waitUntilDone:YES]; // Icons
	[desktop.layer performSelectorOnMainThread:@selector(renderInContext:) withObject:(__bridge id)c waitUntilDone:YES]; // Desktop windows
	
	for (UIView *view in desktop.subviews) // Application views
	{
		if ([view isKindOfClass:[RAWindowBar class]])
		{
			RAHostedAppView *hostedView = [((RAWindowBar*)view) attachedView];

			UIImage *image = [self snapshotForIdentifier:hostedView.bundleIdentifier orientation:hostedView.orientation];
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
	if (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation))
		CGContextRotateCTM(c, DEGREES_TO_RADIANS(90));
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	image = [self rotateImageToMatchOrientation:image];
	MSHookIvar<UIWindow*>([%c(SBWallpaperController) sharedInstance], "_wallpaperWindow").layer.contents = nil;
	[[[%c(SBUIController) sharedInstance] window] layer].contents = nil;
	desktop.layer.contents = nil;
	return image;
}

-(void) forceReloadEverything
{
	[imageCache removeAllObjects];
}
@end