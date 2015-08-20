#import "RAThemeManager.h"
#import "RAThemeLoader.h"
#import "RASettings.h"
#import "headers.h"

@implementation RAThemeManager
+(instancetype) sharedInstance
{
	SHARED_INSTANCE2(RAThemeManager, [sharedInstance invalidateCurrentThemeAndReload:nil]); // will be reloaded by RASettings
}

-(RATheme*) currentTheme { return currentTheme; }
-(NSArray*) allThemes { return allThemes.allValues; }

-(void) invalidateCurrentThemeAndReload:(NSString*)currentIdentifier
{
	currentTheme = nil;
	allThemes = [NSMutableDictionary dictionary];

	NSString *folderName = [NSString stringWithFormat:@"%@/Themes/", RA_BASE_PATH];
	NSArray *themeFileNames = [NSFileManager.defaultManager subpathsAtPath:folderName];

	for (NSString *themeName in themeFileNames)
	{
		if ([themeName hasSuffix:@"plist"] == NO)
			continue;

		RATheme *theme = [RAThemeLoader loadFromFile:themeName];
		if (theme && theme.themeIdentifier)
		{
			//NSLog(@"[ReachApp] adding %@", theme.themeIdentifier);
			allThemes[theme.themeIdentifier] = theme;

			if ([theme.themeIdentifier isEqual:currentIdentifier])
				currentTheme = theme;
		}
	}
	if (!currentTheme)
	{
		currentTheme = [allThemes objectForKey:@"com.eljahandandrew.multiplexer.themes.default"];
		if (!currentTheme && allThemes.allKeys.count > 0)
		{
			currentTheme = allThemes[allThemes.allKeys[0]];
		}
	}
}
@end