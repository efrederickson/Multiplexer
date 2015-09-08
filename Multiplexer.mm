#import "Multiplexer.h"
#import "RACompatibilitySystem.h"
#import "headers.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

@implementation MultiplexerExtension
@end

@implementation Multiplexer
+(instancetype) sharedInstance
{
	SHARED_INSTANCE2(Multiplexer, sharedInstance->activeExtensions = [NSMutableArray array]);
}

-(NSString*) currentVersion { return @"1.0"; }
-(BOOL) isOnSupportedOS { return SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0") && SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"9.0"); }

-(void) registerExtension:(NSString*)name forMultiplexerVersion:(NSString*)version
{
	if ([self.currentVersion compare:version options:NSNumericSearch] == NSOrderedDescending)
	{
		[RACompatibilitySystem showWarning:[NSString stringWithFormat:@"Extension %@ was built for Multiplexer version %@, which is above the current version. Compliancy issues may occur.", name, version]];
	}

	MultiplexerExtension *ext = [[MultiplexerExtension alloc] init];
	ext.name = name;
	ext.multiplexerVersion = version;
	[activeExtensions addObject:ext];
}
@end