#import "RATheme.h"

@interface RAThemeManager : NSObject {
	NSMutableDictionary *allThemes;
	RATheme *currentTheme;
}

+(instancetype) sharedInstance;

-(RATheme*) currentTheme;
-(NSArray*) allThemes;

-(void) invalidateCurrentThemeAndReload:(NSString*)currentIdentifier;
@end