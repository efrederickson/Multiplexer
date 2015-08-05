#import "headers.h"

@interface RASwipeOverManager : NSObject {
	NSString *currentAppIdentifier;
	BOOL isUsingSwipeOver;
}
+(id) sharedInstance;

-(void) startUsingSwipeOver;
-(void) stopUsingSwipeOver;
-(BOOL) isUsingSwipeOver;

-(void) createEdgeView;

-(void) showApp:(NSString*)identifier; // if identifier is nil it will use the app switcher data
-(void) closeCurrentView; // App or selector
-(void) showAppSelector; // No widget chooser, not enough horizontal space. TODO: make it work anyway

-(BOOL) isEdgeViewShowing;
-(void) convertSwipeOverViewToSideBySide;

-(void) sizeViewForTranslation:(CGPoint)translation state:(UIGestureRecognizerState)state;
@end

#define RASWIPEOVER_VIEW_TAG 996
