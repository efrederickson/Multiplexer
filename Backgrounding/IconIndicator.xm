#import "RABackgrounder.h"
#import "RASettings.h"
#import "RAIconBadgeView.h"

NSMutableDictionary *indicatorStateDict = [NSMutableDictionary dictionary];
#define SET_INFO_(x, y)    indicatorStateDict[x] = [NSNumber numberWithInt:y]
#define GET_INFO_(x)       [indicatorStateDict[x] intValue]
#define SET_INFO(y)        if (self.icon && self.icon.application) SET_INFO_(self.icon.application.bundleIdentifier, y);
#define GET_INFO           (self.icon && self.icon.application ? GET_INFO_(self.icon.application.bundleIdentifier) : RAIconIndicatorViewInfoNone)


const char *associated_object_key = "bruh";

NSString *stringFromIndicatorInfo(RAIconIndicatorViewInfo info)
{
	NSMutableString *ret = [[NSMutableString alloc] init];

	if (info & RAIconIndicatorViewInfoNone)
		return nil;

	if ([RASettings.sharedInstance showNativeStateIconIndicators] && (info & RAIconIndicatorViewInfoNative))
		[ret appendString:@"N"];
	
	if (info & RAIconIndicatorViewInfoForced)
		[ret appendString:@"F"];

	//if (info & RAIconIndicatorViewInfoForceDeath)
	//	[ret appendString:@"D"];

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

	if (info == RAIconIndicatorViewInfoTemporarilyInhibit)
	{
		[self RA_setIsIconIndicatorInhibited:YES];
		[self performSelector:@selector(RA_setIsIconIndicatorInhibited:) withObject:@NO afterDelay:1];
		return;
	}

	NSString *text = stringFromIndicatorInfo(info);
	if (
		[self RA_isIconIndicatorInhibited] || 
		(text == nil || text.length == 0) || // OR info == RAIconIndicatorViewInfoNone
		(self.icon == nil || self.icon.application == nil || self.icon.application.isRunning == NO || ![RABackgrounder.sharedInstance shouldShowIndicatorForIdentifier:self.icon.application.bundleIdentifier]) || 
		self.icon == MSHookIvar<SBIcon*>([%c(SBIconController) sharedInstance], "_launchingIcon") ||
		[RASettings.sharedInstance backgrounderEnabled] == NO)
	{
		//SET_INFO(RAIconIndicatorViewInfoNone);
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
	SET_INFO(info);
}

%new -(void) RA_updateIndicatorViewWithExistingInfo
{
	//if ([self viewWithTag:9962])
		[self RA_updateIndicatorView:GET_INFO];
}

%new -(void) RA_setIsIconIndicatorInhibited:(BOOL)value
{
    objc_setAssociatedObject(self, @selector(RA_isIconIndicatorInhibited), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self RA_updateIndicatorViewWithExistingInfo];
}

%new -(BOOL) RA_isIconIndicatorInhibited
{
    return [objc_getAssociatedObject(self, @selector(RA_isIconIndicatorInhibited)) boolValue];
}

-(void) layoutSubviews
{
    %orig;

    [self RA_updateIndicatorView:GET_INFO];
}

- (void)setIsEditing:(_Bool)arg1 animated:(_Bool)arg2
{
	%orig;

	if (arg1)
	{
		// inhibit icon indicator
		[self RA_setIsIconIndicatorInhibited:YES];
	}
	else
	{
		[self RA_setIsIconIndicatorInhibited:NO];
	}
}
%end

%hook SBApplication
- (void)setApplicationState:(unsigned int)arg1
{
    %orig;

    if (self.isRunning == NO)
    	[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:RAIconIndicatorViewInfoNone];
    else 
    {
    	//if ([indicatorStateDict objectForKey:self.bundleIdentifier] == nil)
    		[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:[RABackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier]];
    	//else
	    //	[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:(RAIconIndicatorViewInfo)GET_INFO_(self.bundleIdentifier)];
    }
}
%end

%hook SBIconController
-(void)iconWasTapped:(SBApplicationIcon*)arg1 
{
	[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:arg1.application.bundleIdentifier withInfo:RAIconIndicatorViewInfoTemporarilyInhibit];
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


