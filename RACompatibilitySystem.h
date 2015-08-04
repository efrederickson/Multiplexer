@interface RACompatibilitySystem : NSObject {

}
//+(instancetype) sharedInstance;

+(void) showWarning:(NSString*)info;
+(void) showError:(NSString*)info;
@end