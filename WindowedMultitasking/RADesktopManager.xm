#import "RADesktopManager.h"
#import "RAMissionControlWindow.h"

BOOL overrideUIWindow = NO;

@implementation RADesktopManager
+(instancetype) sharedInstance
{
	SHARED_INSTANCE2(RADesktopManager, 
		sharedInstance->windows = [NSMutableArray array];
		[sharedInstance addDesktop:YES];
		overrideUIWindow = YES;
	);
}

-(void) addDesktop:(BOOL)switchTo
{
	RADesktopWindow *desktopWindow = [[RADesktopWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
	[windows addObject:desktopWindow];
	if (switchTo)
		[self switchToDesktop:windows.count - 1];
}

-(void) removeDesktopAtIndex:(NSUInteger)index
{
	if (windows.count == 1 && index == 0)
		return;

	if (currentDesktopIndex == index)
		[self switchToDesktop:0];

	RADesktopWindow *window = windows[index];
	[window closeAllApps];
	[windows removeObjectAtIndex:index]; 
}

-(NSUInteger) numberOfDesktops
{
	return windows.count;
}

-(void) switchToDesktop:(NSUInteger)index
{
	[self switchToDesktop:index actuallyShow:YES];
}

-(void) switchToDesktop:(NSUInteger)index actuallyShow:(BOOL)show
{
	RADesktopWindow *newDesktop = windows[index];

	currentDesktop.hidden = YES;

	[currentDesktop unloadApps];
	[newDesktop loadApps];

	if (show == NO)
		newDesktop.hidden = YES;
	overrideUIWindow = NO;
	[newDesktop makeKeyAndVisible];
	overrideUIWindow = YES;
	if (show == NO)
		newDesktop.hidden = YES;

	currentDesktopIndex = index;
	currentDesktop = newDesktop;
}

-(void) removeAppWithIdentifier:(NSString*)bundleIdentifier animated:(BOOL)animated
{
	for (RADesktopWindow *window in windows)
	{
		[window removeAppWithIdentifier:bundleIdentifier animated:(BOOL)animated];
	}
}

-(void) hideDesktop
{
	currentDesktop.hidden = YES;
}

-(void) reshowDesktop
{
	currentDesktop.hidden = NO;
}

-(RADesktopWindow*) desktopAtIndex:(NSUInteger)index { return windows[index]; }
-(NSArray*) availableDesktops { return windows; }
-(NSUInteger) currentDesktopIndex { return currentDesktopIndex; }
-(RADesktopWindow*) currentDesktop { return currentDesktop; }
@end

%hook UIWindow
-(void) makeKeyAndVisible
{
	%orig;

	if (overrideUIWindow)
	{
		static Class c1 = [RAMissionControlWindow class];
		static Class c2 = [%c(SBAppSwitcherWindow) class];

		if ([self isKindOfClass:c1] || [self isKindOfClass:c2])
			return;
		if (self != RADesktopManager.sharedInstance.currentDesktop)
		{
			//[RADesktopManager.sharedInstance.currentDesktop performSelector:@selector(_orderFrontWithoutMakingKey)];
			[RADesktopManager.sharedInstance.currentDesktop makeKeyAndVisible];
		}
	}
}
%end


%hook SBUIController
- (void)activateApplicationAnimated:(SBApplication*)arg1
{
	[RADesktopManager.sharedInstance removeAppWithIdentifier:arg1.bundleIdentifier animated:NO];
    %orig;
}
%end

%ctor
{
	if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])
		%init;
}