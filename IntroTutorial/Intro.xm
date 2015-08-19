#import "headers.h"
#import "RASettings.h"

%hook SBLockScreenViewController
- (void)finishUIUnlockFromSource:(int)arg1
{
	%orig;
	if ([RASettings.sharedInstance isFirstRun])
	{
		BBBulletinRequest *request = [[%c(BBBulletinRequest) alloc] init];
		request.title = LOCALIZE(@"MULTIPLEXER");
		request.message = LOCALIZE(@"THANK_YOU_TEXT");
		request.sectionID = @"com.apple.Preferences";
		request.date = [NSDate date];
		request.defaultAction = [%c(BBAction) actionWithLaunchBundleID:@"com.andrewabosh.Multiplexer" callblock:nil];
		request.expirationDate = [[NSDate date] dateByAddingTimeInterval:10];
		SBBulletinBannerController *bannerController = [%c(SBBulletinBannerController) sharedInstance];
		if ([bannerController respondsToSelector:@selector(observer:addBulletin:forFeed:playLightsAndSirens:withReply:)]) 
			[bannerController observer:nil addBulletin:request forFeed:2 playLightsAndSirens:YES withReply:nil];
		else
			[bannerController observer:nil addBulletin:request forFeed:2];
		
		[RASettings.sharedInstance setFirstRun:NO];
	}
}
%end