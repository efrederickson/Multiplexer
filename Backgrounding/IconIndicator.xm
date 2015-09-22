#import "RABackgrounder.h"
#import "RASettings.h"
#import <libstatusbar/LSStatusBarItem.h>
#import <applist/ALApplicationList.h>
#import "ColorBadges.h"
#import "Anemone.h"

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

	if ([[%c(RASettings) sharedInstance] showNativeStateIconIndicators] && (info & RAIconIndicatorViewInfoNative))
		ret = [ret stringByAppendingString:@"N"];
	
	if (info & RAIconIndicatorViewInfoForced)
		ret = [ret stringByAppendingString:@"F"];

	//if (info & RAIconIndicatorViewInfoForceDeath)
	//	[ret appendString:@"D"];

	if (info & RAIconIndicatorViewInfoSuspendImmediately)
		ret = [ret stringByAppendingString:@"ll"];
		
	if (info & RAIconIndicatorViewInfoUnkillable)
		ret = [ret stringByAppendingString:@"U"];

	if (info & RAIconIndicatorViewInfoUnlimitedBackgroundTime)
		ret = [ret stringByAppendingString:@"∞"];

	return ret;
}

%hook SBIconView
%new -(void) RA_updateIndicatorView:(RAIconIndicatorViewInfo)info
{
	@autoreleasepool {
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
			[[%c(RASettings) sharedInstance] backgrounderEnabled] == NO)
		{
			[[self viewWithTag:9962] removeFromSuperview];
			return;
		}

		UILabel *badge = (UILabel*)[self viewWithTag:9962];
		if (!badge)
		{
			badge = [[[UILabel alloc] init] retain];
			badge.tag = 9962;

			badge.textAlignment = NSTextAlignmentCenter;
			badge.clipsToBounds = YES;
			badge.font = [%c(SBIconBadgeView) _textFont];

			// Note that my macros for this deal with the situation where ColorBadges is not installed
			badge.backgroundColor = GET_COLORBADGES_COLOR(self.icon, THEMED(backgroundingIndicatorBackgroundColor));

			//badge.textColor = GET_ACCEPTABLE_TEXT_COLOR(badge.backgroundColor, THEMED(backgroundingIndicatorTextColor));
			if (HAS_COLORBADGES && [%c(ColorBadges) isEnabled])
			{
				int bgColor = RGBFromUIColor(badge.backgroundColor);
				int txtColor = RGBFromUIColor(THEMED(backgroundingIndicatorTextColor));

				if ([%c(ColorBadges) isDarkColor:bgColor])
				{
					// dark color
					if ([%c(ColorBadges) isDarkColor:txtColor])
					{
						// dark + dark
						badge.textColor = [UIColor whiteColor];
					}
					else
					{
						// dark + light
						badge.textColor = THEMED(backgroundingIndicatorTextColor);
					}
				}
				else
				{
					// light color
					if ([%c(ColorBadges) isDarkColor:txtColor])
					{
						// light + dark
						badge.textColor = THEMED(backgroundingIndicatorTextColor);
					}
					else
					{
						//light + light
						badge.textColor = [UIColor blackColor];
					}
				}
			}
			else
			{
				badge.textColor = THEMED(backgroundingIndicatorTextColor);
			}
			UIImage *bgImage = [%c(SBIconBadgeView) _checkoutBackgroundImage];
			if (HAS_ANEMONE && [[[%c(ANEMSettingsManager) sharedManager] themeSettings] containsObject:@"ModernBadges"])
			{
				badge.backgroundColor = [UIColor colorWithPatternImage:bgImage];
			}

			[self addSubview:badge];
			[badge release];

			CGPoint overhang = [%c(SBIconBadgeView) _overhang];
			badge.frame = CGRectMake(-overhang.x, -overhang.y, bgImage.size.width, bgImage.size.height);
			badge.layer.cornerRadius = MAX(badge.frame.size.width, badge.frame.size.height) / 2.0;
		}

		if (HAS_ANEMONE && [[[%c(ANEMSettingsManager) sharedManager] themeSettings] containsObject:@"ModernBadges"])
		{
			UIImageView *textImageView = (UIImageView*)[badge viewWithTag:42];
			if (!textImageView)
			{
				CGFloat padding = [objc_getClass("SBIconBadgeView") _textPadding];
				
				textImageView = [[UIImageView alloc] initWithFrame:CGRectMake(padding, padding, badge.frame.size.width - (padding * 2.0), badge.frame.size.height - (padding * 2.0))];
				textImageView.center = CGPointMake((badge.frame.size.width / 2.0) + [%c(SBIconBadgeView) _textOffset].x, (badge.frame.size.height / 2.0) + [%c(SBIconBadgeView) _textOffset].y);
				textImageView.tag = 42;
				[badge addSubview:textImageView];
			}

			UIImage *textImage = [%c(SBIconBadgeView) _checkoutImageForText:text highlighted:NO];
			textImageView.image = textImage;
		}
		else
			[badge performSelectorOnMainThread:@selector(setText:) withObject:text waitUntilDone:YES];

		SET_INFO(info);
	}
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
    objc_setAssociatedObject(self, @selector(RA_isIconIndicatorInhibited), value ? (id)kCFBooleanTrue : (id)kCFBooleanFalse, OBJC_ASSOCIATION_ASSIGN);
    if (value2 || value == YES)
	    [self RA_updateIndicatorViewWithExistingInfo];
}

-(void) dealloc
{
	if (self)
	{
		UIView *view = [self viewWithTag:9962];
		if (view)
		{
			[view removeFromSuperview];
		}
	}

	%orig;
}

%new -(BOOL) RA_isIconIndicatorInhibited
{
    return [objc_getAssociatedObject(self, @selector(RA_isIconIndicatorInhibited)) boolValue];
}

-(void) layoutSubviews
{
    %orig;

    //if ([self viewWithTag:9962] == nil)
    // this is back in, again, to try to fix "Smartclose badges show randomly in the app switcher for random applications even though I only have one app smart closed"
	//    [self RA_updateIndicatorView:GET_INFO];
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

NSMutableDictionary *lsbitems = [[[NSMutableDictionary alloc] init] retain];

%hook SBApplication

/*

TODO: fix this crash

Last Exception Backtrace:
0       CoreFoundation                	0x273cefea 0x272c7000 + 0x107fea	// __exceptionPreprocess + 0x7a
1       libobjc.A.dylib               	0x35a72c86 0x35a6c000 + 0x6c86  	// objc_exception_throw + 0x22
2       CoreFoundation                	0x273d4404 0x272c7000 + 0x10d404	// -[NSObject(NSObject) doesNotRecognizeSelector:] + 0xb8
3     + ReachApp.dylib                	0x0665540a 0x065d7000 + 0x7e40a 	// Logos hook for -[NSObject(_ungrouped) doesNotRecognizeSelector:](NSObject*, objc_selector*, objc_selector) + 0x1b2
4       CoreFoundation                	0x273d2322 0x272c7000 + 0x10b322	// ___forwarding___ + 0x2c6
5       CoreFoundation                	0x27301e74 0x272c7000 + 0x3ae74 	// _CF_forwarding_prep_0 + 0x14
6     + ReachAppBackgrounding.dylib   	0x0644a252 0x06442000 + 0x8252  	// Logos hook for -[SBApplication(_ungrouped) RA_addStatusBarIconForSelfIfOneDoesNotExist](SBApplication*, objc_selector*) + 0x76
7     + ReachAppBackgrounding.dylib   	0x0644a8b6 0x06442000 + 0x88b6  	// Logos hook for -[SBApplication(_ungrouped) setApplicationState:](SBApplication*, objc_selector*, unsigned int) + 0x156
8       libdispatch.dylib             	0x360032de 0x36002000 + 0x12de  	// _dispatch_call_block_and_release + 0x6
9       libdispatch.dylib             	0x360032ca 0x36002000 + 0x12ca  	// _dispatch_client_callout + 0x12
10      libdispatch.dylib             	0x36006d2a 0x36002000 + 0x4d2a  	// _dispatch_main_queue_callback_4CF + 0x52e
11      CoreFoundation                	0x27394604 0x272c7000 + 0xcd604 	// __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__ + 0x4
12      CoreFoundation                	0x27392d04 0x272c7000 + 0xcbd04 	// __CFRunLoopRun + 0x5e4
13      CoreFoundation                	0x272df1fc 0x272c7000 + 0x181fc 	// CFRunLoopRunSpecific + 0x1d8
14      CoreFoundation                	0x272df00e 0x272c7000 + 0x1800e 	// CFRunLoopRunInMode + 0x66
15      GraphicsServices              	0x2edb01fc 0x2eda7000 + 0x91fc  	// GSEventRunModal + 0x84
16      UIKit                         	0x2aaaba04 0x2aa3c000 + 0x6fa04 	// UIApplicationMain + 0x59c
17    + FolderCloser.dylib            	0x06337fe8 0x06337000 + 0xfe8   	// my_UIApplicationMainX + 0x140
18      SpringBoard (*)               	0x0007f296 0x00077000 + 0x8296  	// 0x00007ae8 + 0x7ae
19      libdyld.dylib                 	0x36024aaa 0x36023000 + 0x1aaa  	// tlv_initializer + 0x2

Tue Sep  8 12:44:18 2015: SpringBoard (com.apple.springboard): [ReachApp] doesNotRecognizeSelector: selector 'objectForKey:' on class '__NSCFString' (image: /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation)
Tue Sep  8 12:44:18 2015: SpringBoard (com.apple.springboard): [ReachApp] Obtained 10 stack frames:
Tue Sep  8 12:44:18 2015: SpringBoard (com.apple.springboard): [ReachApp] 0   ReachApp.dylib                      0x06655379 _ZL59_logos_method$_ungrouped$NSObject$doesNotRecognizeSelector$P8NSObjectP13objc_selectorS1_ + 288
Tue Sep  8 12:44:18 2015: SpringBoard (com.apple.springboard): [ReachApp] 1   CoreFoundation                      0x273d2327 <redacted> + 714
Tue Sep  8 12:44:18 2015: SpringBoard (com.apple.springboard): [ReachApp] 2   CoreFoundation                      0x27301e78 _CF_forwarding_prep_0 + 24
Tue Sep  8 12:44:18 2015: SpringBoard (com.apple.springboard): [ReachApp] 3   ReachAppBackgrounding.dylib         0x0644a257 _ZL82_logos_method$_ungrouped$SBApplication$RA_addStatusBarIconForSelfIfOneDoesNotExistP13SBApplicationP13objc_selector + 122
Tue Sep  8 12:44:18 2015: SpringBoard (com.apple.springboard): [ReachApp] 4   ReachAppBackgrounding.dylib         0x0644a8bb _ZL59_logos_method$_ungrouped$SBApplication$setApplicationState$P13SBApplicationP13objc_selectorj + 346
Tue Sep  8 12:44:18 2015: SpringBoard (com.apple.springboard): [ReachApp] 5   libdispatch.dylib                   0x360032e3 <redacted> + 10
Tue Sep  8 12:44:19 2015: SpringBoard (com.apple.springboard): [ReachApp] 6   libdispatch.dylib                   0x360032cf <redacted> + 22
Tue Sep  8 12:44:19 2015: SpringBoard (com.apple.springboard): [ReachApp] 7   libdispatch.dylib                   0x36006d2f _dispatch_main_queue_callback_4CF + 1330
Tue Sep  8 12:44:19 2015: SpringBoard (com.apple.springboard): [ReachApp] 8   CoreFoundation                      0x27394609 <redacted> + 8
Tue Sep  8 12:44:19 2015: SpringBoard (com.apple.springboard): [ReachApp] 9   CoreFoundation                      0x27392d09 <redacted> + 1512
Tue Sep  8 12:44:19 2015: SpringBoard (com.apple.springboard): -[__NSCFString objectForKey:]: unrecognized selector sent to instance 0x1d50e650
Tue Sep  8 12:44:19 2015: SpringBoard (com.apple.springboard): *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[__NSCFString objectForKey:]: unrecognized selector sent to instance 0x1d50e650'
*** First throw call stack:
(0x273cefef 0x35a72c8b 0x273d4409 0x665540f 0x273d2327 0x27301e78 0x644a257 0x644a8bb 0x360032e3 0x360032cf 0x36006d2f 0x27394609 0x27392d09 0x272df201 0x272df013 0x2edb0201 0x2aaaba09 0x6337fec 0x7f29b 0x36024aaf)

FIXED?: Forgot to -retain the dictionary. (It was autoreleased i believe)

*/
%new -(void) RA_addStatusBarIconForSelfIfOneDoesNotExist
{
#if DEBUG
	if ([lsbitems respondsToSelector:@selector(objectForKey:)] == NO)
	{
		NSLog(@"[ReachApp] ERROR: lsbitems is not NSDictionary it is %s", class_getName(lsbitems.class));
		//@throw [NSException exceptionWithName:@"OH POOP" reason:@"Expected NSDictionary" userInfo:nil];
	}
#endif

	if (objc_getClass("LSStatusBarItem") && [lsbitems objectForKey:self.bundleIdentifier] == nil && [RABackgrounder.sharedInstance shouldShowStatusBarIconForIdentifier:self.bundleIdentifier])
	{
		if ([[[[%c(SBIconViewMap) homescreenMap] iconModel] visibleIconIdentifiers] containsObject:self.bundleIdentifier])
		{
			RAIconIndicatorViewInfo info = [RABackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier];
			BOOL native = (info & RAIconIndicatorViewInfoNative);
			if ((info & RAIconIndicatorViewInfoNone) == 0 && (native == NO || [[%c(RASettings) sharedInstance] shouldShowStatusBarNativeIcons]))
			{
		    	LSStatusBarItem *item = [[%c(LSStatusBarItem) alloc] initWithIdentifier:[NSString stringWithFormat:@"multiplexer-%@",self.bundleIdentifier] alignment:StatusBarAlignmentLeft];
	    		item.customViewClass = @"RAAppIconStatusBarIconView";
	        	item.imageName = [NSString stringWithFormat:@"multiplexer-%@",self.bundleIdentifier];
	    		lsbitems[self.bundleIdentifier] = item;
	    	}
    	}
	}
}

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
    	if ([self respondsToSelector:@selector(RA_addStatusBarIconForSelfIfOneDoesNotExist)])
	    	[self performSelector:@selector(RA_addStatusBarIconForSelfIfOneDoesNotExist)];

		[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:[RABackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier]];
		SET_INFO_(self.bundleIdentifier, [RABackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier]);
    }
}

%new +(void) RA_clearAllStatusBarIcons
{
	lsbitems = [NSMutableDictionary dictionary];
}

- (void)didAnimateActivation
{
	//[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:RAIconIndicatorViewInfoUninhibit];
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
- (id) _iconViewForIcon:(unsafe_id)arg1
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
    return [_UILegibilityImageSet imageFromImage:img withShadowImage:img];
}
-(CGFloat) standardPadding { return 4; }
%end
%hook UIStatusBarCustomItem
-(NSUInteger) leftOrder
{
	if ([self.indicatorName hasPrefix:@"multiplexer-"])
	{
		return 7; // Shows just after vpn, before the loading/sync indicator
	}
	return %orig;
}
%end
%end

%ctor
{
	if ([%c(RASettings) isLibStatusBarInstalled])
	{
		%init(libstatusbar);
	}
	%init;
}
