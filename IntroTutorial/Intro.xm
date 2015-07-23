#import "headers.h"
#import "RASettings.h"

%hook SBLockStateAggregator
-(void) _updateLockState
{
    %orig;
    
    if (![self hasAnyLockState])
    {
		if ([RASettings.sharedInstance isFirstRun])
		{
			BBBulletinRequest *request = [[%c(BBBulletinRequest) alloc] init];
			request.title = @"Multiplexer";
			request.message = @"Thank you for installing Multiplexer! Tap here to view the tutorial.";
			request.sectionID = @"com.apple.Preferences";
			/*request.defaultAction = [%c(BBAction) actionWithCallblock:^{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Multiplexer" message:@"TODO: intro tutorial" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			    [alert show];
			}];*/
			SBBulletinBannerController *bannerController = [%c(SBBulletinBannerController) sharedInstance];
			[bannerController observer:nil addBulletin:request forFeed:2 playLightsAndSirens:YES withReply:^{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Multiplexer" message:@"TODO: intro tutorial" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			    [alert show];
			}];
			[RASettings.sharedInstance setFirstRun:NO];
		}
	}
}
%end