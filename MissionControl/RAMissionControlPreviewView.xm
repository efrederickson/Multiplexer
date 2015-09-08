#import "RAMissionControlPreviewView.h"
#import "RASnapshotProvider.h"
#import "RADesktopWindow.h"

@implementation RAMissionControlPreviewView
-(void) generatePreview
{
    [self performSelectorOnMainThread:@selector(setBackgroundColor:) withObject:[[UIColor blackColor] colorWithAlphaComponent:0.5] waitUntilDone:NO];
	//self.image = [[%c(RASnapshotProvider) sharedInstance] snapshotForIdentifier:self.application.bundleIdentifier];
    UIImage *img = [[%c(RASnapshotProvider) sharedInstance] snapshotForIdentifier:self.application.bundleIdentifier];
    [self performSelectorOnMainThread:@selector(setImage:) withObject:img waitUntilDone:NO];

    //if (!icon)
    //  icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:self.application.bundleIdentifier];
    //if (icon && !iconView)
    //    iconView = [[%c(SBIconViewMap) homescreenMap] _iconViewForIcon:icon];

    NSOperationQueue* targetQueue = [NSOperationQueue mainQueue];
    [targetQueue addOperationWithBlock:^{
        if (!icon)
          icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:self.application.bundleIdentifier];
        if (icon && !iconView)
            iconView = [[%c(SBIconViewMap) homescreenMap] _iconViewForIcon:icon];
    }];
    [targetQueue waitUntilAllOperationsAreFinished];

    iconView.layer.shadowRadius = THEMED(missionControlIconPreviewShadowRadius); // iconView.layer.cornerRadius;
    iconView.layer.shadowOpacity = 0.8;
    iconView.layer.shadowOffset = CGSizeMake(0, 0);
    iconView.layer.shouldRasterize = YES;
    iconView.layer.rasterizationScale = UIScreen.mainScreen.scale;
    iconView.userInteractionEnabled = NO;
	iconView.iconLabelAlpha = 0;

    [self performSelectorOnMainThread:@selector(addSubview:) withObject:iconView waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(updateIconViewFrame) withObject:nil waitUntilDone:NO];
}

-(void) generatePreviewAsync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self generatePreview];
    });
}

-(void) generateDesktopPreviewAsync:(id)desktop_ completion:(dispatch_block_t)completionBlock
{
    RADesktopWindow *desktop = (RADesktopWindow*)desktop_;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        UIImage *image = [[%c(RASnapshotProvider) sharedInstance] snapshotForDesktop:desktop];
        [self performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
        if (completionBlock)
            completionBlock();
    });
}

-(void) updateIconViewFrame
{
	if (!iconView)
		return;
	[self bringSubviewToFront:iconView];
	iconView.frame = CGRectMake( (self.frame.size.width / 2) - (iconView.frame.size.width / 2), (self.frame.size.height / 2) - (iconView.frame.size.height / 2), iconView.frame.size.width, iconView.frame.size.height );
}
@end