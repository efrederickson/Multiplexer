#import "RATheme.h"

@interface RAThemeManager : NSObject
+(instancetype) sharedInstance;

-(RATheme*) currentTheme;
-(NSArray*) allThemes;
@end