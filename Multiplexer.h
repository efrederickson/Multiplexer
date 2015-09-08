@interface MultiplexerExtension : NSObject
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *multiplexerVersion;
@end

@interface Multiplexer : NSObject {
	NSMutableArray *activeExtensions;
}
+(instancetype) sharedInstance;

-(NSString*) currentVersion;
-(BOOL) isOnSupportedOS;

-(void) registerExtension:(NSString*)name forMultiplexerVersion:(NSString*)version;
@end
