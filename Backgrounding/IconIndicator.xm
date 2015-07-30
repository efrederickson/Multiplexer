#import "RABackgrounder.h"
#import "RASettings.h"
#import "RAIconBadgeView.h"

NSMutableArray *managedIconViews = [NSMutableArray array];

NSMutableDictionary *indicatorStateDict = [NSMutableDictionary dictionary];
#define SET_INFO_(x, y)    indicatorStateDict[x] = [NSNumber numberWithInt:y]
#define GET_INFO_(x)       [indicatorStateDict[x] intValue]
#define SET_INFO(y)        if (self.icon && self.icon.application) SET_INFO_(self.icon.application.bundleIdentifier, y);
#define GET_INFO           (self.icon && self.icon.application ? GET_INFO_(self.icon.application.bundleIdentifier) : RAIconIndicatorViewInfoNone)


NSString *stringFromIndicatorInfo(RAIconIndicatorViewInfo info)
{
	NSMutableString *ret = [[NSMutableString alloc] init];

	if (info & RAIconIndicatorViewInfoNone)
		return nil;

	if ([RASettings.sharedInstance showNativeStateIconIndicators] && (info & RAIconIndicatorViewInfoNative))
		[ret appendString:@"N"];
	
	if (info & RAIconIndicatorViewInfoForced)
		[ret appendString:@"F"];

	if (info & RAIconIndicatorViewInfoForceDeath)
		[ret appendString:@"D"];

	if (info & RAIconIndicatorViewInfoSuspendImmediately)
		[ret appendString:@"S"];
		
	if (info & RAIconIndicatorViewInfoUnkillable)
		[ret appendString:@"U"];

	if (info & RAIconIndicatorViewInfoUnlimitedBackgroundTime)
		[ret appendString:@"B"];

	return ret;
}

%hook SBIconView
%new -(void) RA_updateIndicatorView:(RAIconIndicatorViewInfo)info
{
	[[self viewWithTag:9962] removeFromSuperview];

	NSString *text = stringFromIndicatorInfo(info);
	if ((text == nil || text.length == 0) || (self.icon == nil || self.icon.application == nil || self.icon.application.isRunning == NO || ![RABackgrounder.sharedInstance shouldShowIndicatorForIdentifier:self.icon.application.bundleIdentifier]) || [RASettings.sharedInstance backgrounderEnabled] == NO)
	{
		[managedIconViews removeObject:self];
		SET_INFO(0);
		return;
	}

	RAIconBadgeView *badge = (RAIconBadgeView*)[self viewWithTag:9962];
	if (!badge)
	{
		badge = [[RAIconBadgeView alloc] init];
		badge.tag = 9962;

		badge.textColor = UIColor.whiteColor;
		badge.textAlignment = NSTextAlignmentCenter;
		badge.clipsToBounds = YES;
		badge.layer.cornerRadius = 12;
		badge.backgroundColor = [UIColor colorWithRed:60/255.0f green:108/255.0f blue:255/255.0f alpha:1.0f];
	}

	badge.text = text;

	if (!badge.superview)
		[self addSubview:badge];

	CGPoint overhang = [%c(SBIconBadgeView) _overhang];
	badge.frame = CGRectMake(-overhang.x, -overhang.y, badge.frame.size.width, badge.frame.size.height);
	if ([managedIconViews containsObject:self] == NO)
		[managedIconViews addObject:self];
	SET_INFO(info);
}

%new -(void) RA_updateIndicatorViewWithExistingInfo
{
	//if ([self viewWithTag:9962])
		[self RA_updateIndicatorView:GET_INFO];
}

-(void) layoutSubviews
{
    %orig;

    [self RA_updateIndicatorView:GET_INFO];
}
%end

%hook SBApplication
- (void)setApplicationState:(unsigned int)arg1
{
    %orig;

    if (self.isRunning == NO)
    	[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:RAIconIndicatorViewInfoNone];

    //for (SBIconView *view in [managedIconViews copy])
    //	[view RA_updateIndicatorViewWithExistingInfo];
}
%end

%hook SBIconController
-(void)iconWasTapped:(SBApplicationIcon*)arg1 
{
	[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:arg1.application.bundleIdentifier withInfo:RAIconIndicatorViewInfoNone];
	%orig;
}
%end

%hook SBIconViewMap
- (id)mappedIconViewForIcon:(id)arg1
{
    SBIconView *iconView = %orig;

    [iconView RA_updateIndicatorViewWithExistingInfo];
    return iconView;
}
%end


