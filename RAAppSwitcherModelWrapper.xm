#import "RAAppSwitcherModelWrapper.h"

@implementation RAAppSwitcherModelWrapper
+(void) addToFront:(SBApplication*)app
{
	SBAppSwitcherModel *model = [%c(SBAppSwitcherModel) sharedInstance];
	if ([model respondsToSelector:@selector(addToFront:)]) // iOS 7 + 8
	{
		SBDisplayLayout *layout = [%c(SBDisplayLayout) fullScreenDisplayLayoutForApplication:app];
	    [model addToFront:layout];
	}
	else // iOS 9
	{
		SBDisplayItem *layout = [%c(SBDisplayItem) displayItemWithType:@"App" displayIdentifier:app.bundleIdentifier];
		[model addToFront:layout role:2];
	}

}

+(void) addIdentifierToFront:(NSString*)ident
{
	[RAAppSwitcherModelWrapper addToFront:[[%c(SBApplicationController) sharedInstance] RA_applicationWithBundleIdentifier:ident]];
}

+(NSArray*) appSwitcherAppIdentiferList
{
	SBAppSwitcherModel *model = [%c(SBAppSwitcherModel) sharedInstance];

	if ([model respondsToSelector:@selector(snapshotOfFlattenedArrayOfAppIdentifiersWhichIsOnlyTemporary)])
		return [model snapshotOfFlattenedArrayOfAppIdentifiersWhichIsOnlyTemporary];

	// iOS 9 most likely. 

	NSMutableArray *ret = [NSMutableArray array];

	id list = [model mainSwitcherDisplayItems]; // NSArray<SBDisplayItem>
	for (SBDisplayItem *item in list)
	{
		[ret addObject:item.displayIdentifier];
	}

	return ret;
}

+(void) removeItemWithIdentifier:(NSString*)ident
{
    SBDisplayItem *item = [%c(SBDisplayItem) displayItemWithType:@"App" displayIdentifier:ident];
    id appSwitcherModel = [%c(SBAppSwitcherModel) sharedInstance];
    if ([appSwitcherModel respondsToSelector:@selector(removeDisplayItem:)])
        [[%c(SBAppSwitcherModel) sharedInstance] removeDisplayItem:item];
    else
        [[%c(SBAppSwitcherModel) sharedInstance] remove:item];
}
@end
