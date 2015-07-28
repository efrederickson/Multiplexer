@interface RALockStateUpdater : NSObject {
	NSMutableDictionary *dict;
	BOOL lastState;
}
+(id) sharedInstance;

-(void) addRequester:(void (^)(BOOL isLocked))block forIdentifier:(NSString*)ident;
-(void) removeRequesterForIdentifier:(NSString*)ident;
@end