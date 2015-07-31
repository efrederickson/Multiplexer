@interface RALocalizer : NSObject {
	NSDictionary *translation;
}
+(id) sharedInstance;

-(NSString*) localizedStringForKey:(NSString*)key;
@end