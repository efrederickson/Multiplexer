#import "RABackgrounder.h"
#import "RASettings.h"
#import "RAIconBadgeView.h"
#import <libstatusbar/LSStatusBarItem.h>
#import <applist/ALApplicationList.h>

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

NSMutableDictionary *lsbitems = [NSMutableDictionary dictionary];

%hook SBApplication
- (void)setApplicationState:(unsigned int)arg1
{
    %orig;

    if (self.isRunning == NO)
    {
    	[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:RAIconIndicatorViewInfoNone];
    	[lsbitems removeObjectForKey:self.bundleIdentifier];
    }
    else 
    {
    	if (objc_getClass("LSStatusBarItem") && [lsbitems objectForKey:self.bundleIdentifier] == nil && [RABackgrounder.sharedInstance shouldShowStatusBarIconForIdentifier:self.bundleIdentifier])
    	{
    		if ([[[[%c(SBIconViewMap) homescreenMap] iconModel] visibleIconIdentifiers] containsObject:self.bundleIdentifier])
    		{
    			RAIconIndicatorViewInfo info = [RABackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier];
    			if ((info & RAIconIndicatorViewInfoNone) == 0 && (info & RAIconIndicatorViewInfoNative) == 0)
    			{
			    	LSStatusBarItem *item = [[%c(LSStatusBarItem) alloc] initWithIdentifier:self.bundleIdentifier alignment:StatusBarAlignmentLeft];
		    		item.customViewClass = @"RAAppIconStatusBarIconView";
		        	item.imageName = [NSString stringWithFormat:@"multiplexer-%@",self.bundleIdentifier];
		    		lsbitems[self.bundleIdentifier] = item;
		    	}
	    	}
    	}

    	//if ([indicatorStateDict objectForKey:self.bundleIdentifier] == nil)
    		[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:[RABackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier]];
    	//else
	    //	[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:(RAIconIndicatorViewInfo)GET_INFO_(self.bundleIdentifier)];
    }
}

%new +(void) RA_clearAllStatusBarIcons
{
	lsbitems = [NSMutableDictionary dictionary];
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

%group libstatusbar
@interface RAAppIconStatusBarIconView : UIView
@property (nonatomic, retain) UIStatusBarItem *item;
@end

@interface UIStatusBarCustomItem : UIStatusBarItem
@end

inline NSString *getAppNameFromIndicatorName(NSString *indicatorName)
{
	return [indicatorName substringFromIndex:(@"multiplexer-").length];
}

%subclass RAAppIconStatusBarIconView : UIStatusBarCustomItemView
-(id) contentsImage
{
	UIImage *img = [ALApplicationList.sharedApplicationList iconOfSize:15 forDisplayIdentifier:getAppNameFromIndicatorName(self.item.indicatorName)];

    return [_UILegibilityImageSet imageFromImage:img withShadowImage:nil];
}
-(CGFloat) standardPadding { return 4; }
%end
%hook UIStatusBarCustomItem
-(NSUInteger) leftOrder
{
	if ([self.indicatorName hasPrefix:@"multiplexer-"])
	{
		//NSString *actualName = getAppNameFromIndicatorName(self.indicatorName);
		return 4; // Shows just after wifi, before the loading/sync indicator
	}
	return %orig;
}
%end
%end

%ctor
{
	if ([NSFileManager.defaultManager fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/libstatusbar.dylib"])
	{
        dlopen("/Library/MobileSubstrate/DynamicLibraries/libstatusbar.dylib", RTLD_NOW | RTLD_GLOBAL);
		%init(libstatusbar);
	}
	%init;
}
