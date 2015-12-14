#import "RADesktopManager.h"
#import "RAMissionControlWindow.h"
#import "RAWindowBar.h"

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
	RADesktopWindow *desktopWindow = [[RADesktopWindow alloc] initWithFrame:UIScreen.mainScreen._referenceBounds];

	[windows addObject:desktopWindow];
	if (switchTo)
		[self switchToDesktop:windows.count - 1];
	[desktopWindow loadInfo:[windows indexOfObject:desktopWindow]];
}

-(void) removeDesktopAtIndex:(NSUInteger)index
{
	if (windows.count == 1 && index == 0)
		return;

	if (currentDesktopIndex == index)
		[self switchToDesktop:0];

	RADesktopWindow *window = windows[index];
	[window saveInfo];
	[window closeAllApps];
	[windows removeObjectAtIndex:index]; 
}

-(BOOL) isAppOpened:(NSString*)identifier
{
	for (RADesktopWindow *desktop in windows)
		if ([desktop isAppOpened:identifier])
			return YES;
	return NO;
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
	//[newDesktop updateForOrientation:UIApplication.sharedApplication.statusBarOrientation];
}

-(void) removeAppWithIdentifier:(NSString*)bundleIdentifier animated:(BOOL)animated
{
	[self removeAppWithIdentifier:bundleIdentifier animated:animated forceImmediateUnload:NO];
}

-(void) removeAppWithIdentifier:(NSString*)bundleIdentifier animated:(BOOL)animated forceImmediateUnload:(BOOL)force
{
	for (RADesktopWindow *window in windows)
	{
		[window removeAppWithIdentifier:bundleIdentifier animated:animated forceImmediateUnload:force];
	}
}

-(RAWindowBar*) windowForIdentifier:(NSString*)identifier
{
	for (RADesktopWindow *desktop in windows)
		if ([desktop isAppOpened:identifier])
			return [desktop windowForIdentifier:identifier];
	return nil;
}

-(void) hideDesktop
{
	currentDesktop.hidden = YES;
}

-(void) reshowDesktop
{
	currentDesktop.hidden = NO;
}

-(void) updateRotationOnClients:(UIInterfaceOrientation)orientation
{
	for (RADesktopWindow *w in windows)
		[w updateRotationOnClients:orientation];
}

-(void) updateWindowSizeForApplication:(NSString*)identifier
{
	for (RADesktopManager *w in windows)
		[w updateWindowSizeForApplication:identifier];
}

-(void) setLastUsedWindow:(RAWindowBar*)window
{
	if (_lastUsedWindow)
	{
		[_lastUsedWindow resignForemostApp];
	}
	_lastUsedWindow = window;
	[_lastUsedWindow becomeForemostApp];
}

-(void) findNewForemostApp
{
	RADesktopWindow *desktop = [self currentDesktop];
	for (RAHostedAppView *hostedApp in desktop.hostedWindows)
	{
		RAWindowBar *bar = [desktop windowForIdentifier:hostedApp.app.bundleIdentifier];
		if (bar)
		{
			self.lastUsedWindow = bar;
			return;
		}
	}
	//self.lastUsedWindow = nil;
}

-(RADesktopWindow*) desktopAtIndex:(NSUInteger)index { return windows[index]; }
-(NSArray*) availableDesktops { return windows; }
-(NSUInteger) currentDesktopIndex { return currentDesktopIndex; }
-(RADesktopWindow*) currentDesktop { return currentDesktop; }
@end

/*
%hook UIWindow
-(void) makeKeyAndVisible
{
	%orig;

	if (overrideUIWindow)
	{
		static Class c1 = [%c(RAMissionControlWindow) class];
		static Class c2 = [%c(SBAppSwitcherWindow) class];

		if ([self isKindOfClass:c1] || [self isKindOfClass:c2])
			return;
		__weak RADesktopWindow *currentDesktop = RADesktopManager.sharedInstance.currentDesktop;
		if (currentDesktop && self != currentDesktop && currentDesktop.hidden == NO)
		{
			//[RADesktopManager.sharedInstance.currentDesktop performSelector:@selector(_orderFrontWithoutMakingKey)];
			[currentDesktop makeKeyAndVisible];
		}
	}
}
%end
*/

%hook SpringBoard
-(void)noteInterfaceOrientationChanged:(UIInterfaceOrientation)arg1 duration:(CGFloat)arg2
{
	%orig;
	[RADesktopManager.sharedInstance updateRotationOnClients:arg1];
}
%end

%ctor
{
	if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])
		%init;
}