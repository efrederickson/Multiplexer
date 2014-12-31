#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"
#import <notify.h>

@interface ReachAppFlipswitchSwitch : NSObject <FSSwitchDataSource>
@end

@implementation ReachAppFlipswitchSwitch

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
	Boolean keyExistsAndHasValidFormat;
	BOOL enabled = CFPreferencesGetAppBooleanValue(CFSTR("enabled"), CFSTR("com.efrederickson.reachapp.settings"), &keyExistsAndHasValidFormat);

	return enabled ? FSSwitchStateOn : FSSwitchStateOff;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier
{
	if (newState == FSSwitchStateIndeterminate)
		return;

	CFPreferencesSetAppValue(CFSTR("enabled"), (CFPropertyListRef)(newState == FSSwitchStateOn ? @YES : @NO), CFSTR("com.efrederickson.reachapp.settings"));
	notify_post("com.efrederickson.reachapp.settings/reloadSettings");
}

@end