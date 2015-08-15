#import "RATheme.h"

@interface RAThemeLoader : NSObject
+(RATheme*)loadFromFile:(NSString*)baseName;

+(RATheme*) themeFromDictionary:(NSDictionary*)dict;
@end