@interface RASwipeOverManager : NSObject
+(id) sharedInstance;

-(void) startUsingSwipeOver;
-(void) stopUsingSwipeOver;
-(BOOL) isUsingSwipeOver;

-(void) showApp:(NSString*)identifier; // if identifier is nil it will use the app switcher data
-(void) closeCurrentView; // App or selector
-(void) showAppSelector;

-(BOOL) isEdgeViewShowing;
-(void) convertSwipeOverViewToSideBySide;

@end