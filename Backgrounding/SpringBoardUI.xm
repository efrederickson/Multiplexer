#import "RABackgrounder.h"

%hook SBIconViewMap
- (id)_iconViewForIcon:(id)arg1
{
	SBIconView *ret = %orig;

	BOOL isValid = ret.icon.application != nil;
	if (isValid)
		isValid = isValid && [RABackgrounder.sharedInstance hasBackgroundStateIconInfoForIdentifier:ret.icon.application.bundleIdentifier];
	if (isValid)
	{
		UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 15)];
		descriptionLabel.backgroundColor = [UIColor redColor];
		descriptionLabel.text = [RABackgrounder.sharedInstance descriptionForBackgroundStateInfoWithIdentifier:ret.icon.application.bundleIdentifier];
		descriptionLabel.tag = 999;
		[ret addSubview:descriptionLabel];
	}
	else
		[[ret viewWithTag:999] removeFromSuperview];

	return ret;
}
%end