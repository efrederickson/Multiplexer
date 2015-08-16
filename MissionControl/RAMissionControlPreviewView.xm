#import "RAMissionControlPreviewView.h"
#import "RASnapshotProvider.h"

@implementation RAMissionControlPreviewView
-(void) generatePreview
{
	self.image = [RASnapshotProvider.sharedInstance snapshotForIdentifier:self.application.bundleIdentifier];

	if (!icon)
    	icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:self.application.bundleIdentifier];
    if (icon && !iconView)
	    iconView = [[%c(SBIconViewMap) homescreenMap] _iconViewForIcon:icon];

    iconView.layer.shadowRadius = THEMED(missionControlIconPreviewShadowRadius); // iconView.layer.cornerRadius;
    iconView.layer.shadowOpacity = 0.8;
    iconView.layer.shadowOffset = CGSizeMake(0, 0);
    iconView.layer.shouldRasterize = YES;
    iconView.userInteractionEnabled = NO;
	iconView.iconLabelAlpha = 0;

    [self addSubview:iconView];
    [self updateIconViewFrame];
}

-(void) updateIconViewFrame
{
	if (!iconView)
		return;
	[self bringSubviewToFront:iconView];
	iconView.frame = CGRectMake( (self.frame.size.width / 2) - (iconView.frame.size.width / 2), (self.frame.size.height / 2) - (iconView.frame.size.height / 2), iconView.frame.size.width, iconView.frame.size.height );
}
@end