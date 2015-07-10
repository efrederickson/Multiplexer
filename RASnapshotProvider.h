@interface RASnapshotProvider : NSObject {
	NSCache *imageCache;
}
+(id) sharedInstance;

-(UIImage*) snapshotForIdentifier:(NSString*)identifier;
-(void) forceReloadOfSnapshotForIdentifier:(NSString*)identifier;
@end