#import "RAMissionControlPreviewView.h"
#import "RASnapshotProvider.h"

@implementation RAMissionControlPreviewView
-(void) generatePreview
{
	self.image = [RASnapshotProvider.sharedInstance snapshotForIdentifier:self.application.bundleIdentifier];

    SBIcon *icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:self.application.bundleIdentifier];
    iconView = [[%c(SBIconViewMap) homescreenMap] _iconViewForIcon:icon];
    [self addSubview:iconView];
    [self updateIconViewFrame];
}

-(void) updateIconViewFrame
{
	if (!iconView)
		return;
	[self bringSubviewToFront:iconView];
	// slightly offscreen
	//iconView.center = CGPointMake(self.center.x, self.frame.size.height);
	//iconView.frame = CGRectMake((self.frame.size.width / 2) - (iconView.frame.size.width / 2), self.frame.size.height - (iconView.frame.size.height / 2), iconView.frame.size.width, iconView.frame.size.height);
	// bottom aligned
	//iconView.frame = CGRectMake((self.frame.size.width / 2) - (iconView.frame.size.width / 2), self.frame.size.height - (iconView.frame.size.height), iconView.frame.size.width, iconView.frame.size.height);
	// center
	iconView.frame = CGRectMake( (self.frame.size.width / 2) - (iconView.frame.size.width / 2), (self.frame.size.height / 2) - (iconView.frame.size.height / 2), iconView.frame.size.width, iconView.frame.size.height );
	iconView.iconLabelAlpha = 0;
}

-(void) setFrame:(CGRect)frame
{
	[super setFrame:frame];
	[self updateIconViewFrame];
}
@end