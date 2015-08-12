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


NSString *stringFromIndicatorInfo(RAIconIndicatorViewInfo info)
{
	NSString *ret = @"";

	if (info & RAIconIndicatorViewInfoNone)
		return nil;

	if ([RASettings.sharedInstance showNativeStateIconIndicators] && (info & RAIconIndicatorViewInfoNative))
		ret = [ret stringByAppendingString:@"N"];
	
	if (info & RAIconIndicatorViewInfoForced)
		ret = [ret stringByAppendingString:@"F"];

	//if (info & RAIconIndicatorViewInfoForceDeath)
	//	[ret appendString:@"D"];

	if (info & RAIconIndicatorViewInfoSuspendImmediately)
		ret = [ret stringByAppendingString:@"S"];
		
	if (info & RAIconIndicatorViewInfoUnkillable)
		ret = [ret stringByAppendingString:@"U"];

	if (info & RAIconIndicatorViewInfoUnlimitedBackgroundTime)
		ret = [ret stringByAppendingString:@"B"];

	return ret;
}

%hook SBIconView
%new -(void) RA_updateIndicatorView:(RAIconIndicatorViewInfo)info
{
	if (info == RAIconIndicatorViewInfoTemporarilyInhibit || info == RAIconIndicatorViewInfoInhibit)
	{
		[[self viewWithTag:9962] removeFromSuperview];
		[self RA_setIsIconIndicatorInhibited:YES];
		if (info == RAIconIndicatorViewInfoTemporarilyInhibit)
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ 
				[self RA_setIsIconIndicatorInhibited:NO showAgainImmediately:NO];
			});
		return;
	}
	else if (info == RAIconIndicatorViewInfoUninhibit)
	{
		[self RA_setIsIconIndicatorInhibited:NO showAgainImmediately:NO];
	}

	NSString *text = stringFromIndicatorInfo(info);

	if (
		[self RA_isIconIndicatorInhibited] || 
		(text == nil || text.length == 0) || // OR info == RAIconIndicatorViewInfoNone
		(self.icon == nil || self.icon.application == nil || self.icon.application.isRunning == NO || ![RABackgrounder.sharedInstance shouldShowIndicatorForIdentifier:self.icon.application.bundleIdentifier]) ||
		[RASettings.sharedInstance backgrounderEnabled] == NO)
	{
		[[self viewWithTag:9962] removeFromSuperview];
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
		[self addSubview:badge];

		CGPoint overhang = [%c(SBIconBadgeView) _overhang];
		badge.frame = CGRectMake(-overhang.x, -overhang.y, badge.frame.size.width, badge.frame.size.height);
	}

	badge.text = text;
	SET_INFO(info);
}

%new -(void) RA_updateIndicatorViewWithExistingInfo
{
	//if ([self viewWithTag:9962])
		[self RA_updateIndicatorView:GET_INFO];
}

%new -(void) RA_setIsIconIndicatorInhibited:(BOOL)value
{
	[self RA_setIsIconIndicatorInhibited:value showAgainImmediately:YES];
}

%new -(void) RA_setIsIconIndicatorInhibited:(BOOL)value showAgainImmediately:(BOOL)value2
{
    objc_setAssociatedObject(self, @selector(RA_isIconIndicatorInhibited), @(value), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (value2 || value == YES)
	    [self RA_updateIndicatorViewWithExistingInfo];
}


%new -(BOOL) RA_isIconIndicatorInhibited
{
    return [objc_getAssociatedObject(self, @selector(RA_isIconIndicatorInhibited)) boolValue];
}

/*-(void) layoutSubviews
{
    %orig;

    //if ([self viewWithTag:9962] == nil)
	    [self RA_updateIndicatorView:GET_INFO];
}*/

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
    	//SET_INFO_(self.bundleIdentifier, RAIconIndicatorViewInfoNone);
    	[lsbitems removeObjectForKey:self.bundleIdentifier];
    }
    else 
    {
    	if (objc_getClass("LSStatusBarItem") && [lsbitems objectForKey:self.bundleIdentifier] == nil && [RABackgrounder.sharedInstance shouldShowStatusBarIconForIdentifier:self.bundleIdentifier])
    	{
    		if ([[[[%c(SBIconViewMap) homescreenMap] iconModel] visibleIconIdentifiers] containsObject:self.bundleIdentifier])
    		{
    			RAIconIndicatorViewInfo info = [RABackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier];
    			BOOL native = (info & RAIconIndicatorViewInfoNative);
    			if ((info & RAIconIndicatorViewInfoNone) == 0 && (native == NO || [RASettings.sharedInstance shouldShowStatusBarNativeIcons]))
    			{
			    	LSStatusBarItem *item = [[%c(LSStatusBarItem) alloc] initWithIdentifier:[NSString stringWithFormat:@"multiplexer-%@",self.bundleIdentifier] alignment:StatusBarAlignmentLeft];
		    		item.customViewClass = @"RAAppIconStatusBarIconView";
		        	item.imageName = [NSString stringWithFormat:@"multiplexer-%@",self.bundleIdentifier];
		    		lsbitems[self.bundleIdentifier] = item;
		    	}
	    	}
    	}

    	//if ([indicatorStateDict objectForKey:self.bundleIdentifier] == nil)
    		[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:[RABackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier]];
    		SET_INFO_(self.bundleIdentifier, [RABackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier]);
    	//else
	    //	[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:(RAIconIndicatorViewInfo)GET_INFO_(self.bundleIdentifier)];
    }
}

%new +(void) RA_clearAllStatusBarIcons
{
	lsbitems = [NSMutableDictionary dictionary];
}

- (void)didAnimateActivation
{
	[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:RAIconIndicatorViewInfoUninhibit];
	[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:RAIconIndicatorViewInfoTemporarilyInhibit];
	%orig;
}
- (void)willAnimateActivation
{
	[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:RAIconIndicatorViewInfoInhibit];
	%orig;
}
%end

%hook SBIconViewMap
- (id)mappedIconViewForIcon:(unsafe_id)arg1
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
