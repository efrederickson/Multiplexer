#import "RASettings.h"


extern id/*RANCViewController* */ ncAppViewController;


#define BOOL(key, default) ([_settings objectForKey:key] != nil ? [_settings[key] boolValue] : default) 

NSDictionary *_settings = nil;

@implementation RASettings
+(id)sharedInstance
{
	RASettings *shared = nil;
	if (shared == nil)
		shared = [[RASettings alloc] init];
	return shared;
}

-(id) init
{
	if (self = [super init])
	{
		[self reloadSettings];
	}
	return self;
}

-(void) reloadSettings
{
	// Prepare specialized setting change cases
	NSString *previousNCAppSetting = self.NCApp;

	// Reload Settings
	if (_settings)
		_settings = nil;
	CFStringRef appID = CFSTR("com.efrederickson.reachapp.settings");
	CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (!keyList) {
		return;
	}
	_settings = (__bridge NSDictionary *)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (!_settings) {
		return;
	}
	CFRelease(keyList);

	if ([previousNCAppSetting isEqual:self.NCApp] == NO)
		[ncAppViewController performSelector:@selector(forceReloadAppLikelyBecauseTheSettingChanged)];
}

-(BOOL) enabled
{
	return BOOL(@"enabled", YES);
}

-(BOOL) disableAutoDismiss
{
	return BOOL(@"disableAutoDismiss", YES);
}

-(BOOL) enableRotation
{
	return BOOL(@"enableRotation", YES);
}

-(BOOL) showNCInstead
{
	return BOOL(@"showNCInstead", NO);
}

-(BOOL) homeButtonClosesReachability
{
	return BOOL(@"homeButtonClosesReachability", YES);
}

-(BOOL) showBottomGrabber
{
	return BOOL(@"showBottomGrabber", NO);
}

-(BOOL) showWidgetSelector
{
	return BOOL(@"showAppSelector", YES);
}

-(BOOL) scalingRotationMode
{
	return BOOL(@"rotationMode", NO);
}

-(BOOL) autoSizeWidgetSelector
{
	return BOOL(@"autoSizeAppChooser", YES);
}

-(BOOL) showAllAppsInWidgetSelector
{
	//NSLog(@"ReachApp: %@ %@", _settings, @(BOOL(@"showAllAppsInAppChooser", YES)));
	return BOOL(@"showAllAppsInAppChooser", YES);
}

-(BOOL) showRecentAppsInWidgetSelector
{
	return BOOL(@"showRecents", YES);
}

-(BOOL) pagingEnabled
{
	return BOOL(@"pagingEnabled", YES);
}

-(NSMutableArray*) favoriteApps
{
	NSMutableArray *favorites = [[NSMutableArray alloc] init];
	for (NSString *key in _settings.allKeys)
	{
		if ([key hasPrefix:@"Favorites-"])
		{
			NSString *ident = [key substringFromIndex:10];
			if ([_settings[key] boolValue])
				[favorites addObject:ident];
		}
	}
	return favorites;
}

-(BOOL) unifyStatusBar
{
	return BOOL(@"unifyStatusBar", YES);
}

-(BOOL) flipTopAndBottom
{
	return BOOL(@"flipTopAndBottom", NO);
}

-(NSString*) NCApp
{
	return _settings[@"NCApp"];
}

-(BOOL) alwaysEnableGestures
{
	return BOOL(@"alwaysEnableGestures", YES);
}

-(BOOL) snapWindows
{
	return BOOL(@"snapWindows", YES);
}

-(BOOL) launchIntoWindows
{
	return BOOL(@"launchIntoWindows", NO);
}
@end