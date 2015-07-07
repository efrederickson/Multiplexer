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

#define SEND_RESIZE_TO_UNDERLYING_APP(frm) \
	NSMutableDictionary *dict = [NSMutableDictionary dictionary]; \
	dict[@"sizeWidth"] = @(frm.width); \
	dict[@"sizeHeight"] = @(frm.height); \
	dict[@"bundleIdentifier"] = currentAppIdentifier; \
	dict[@"isTopApp"] = @NO; \
    dict[@"rotationMode"] = @NO; \
    dict[@"hideStatusBarIfWanted"] = @NO; \
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.beginresizing"), NULL, (__bridge CFDictionaryRef)dict, true);

#define SEND_RESIZE_TO_OVERLYING_APP(frm) \
	NSMutableDictionary *dict__overlying = [NSMutableDictionary dictionary]; \
	dict__overlying[@"sizeWidth"] = @(frm.width); \
	dict__overlying[@"sizeHeight"] = @(frm.height); \
	dict__overlying[@"bundleIdentifier"] = currentHostingIdentifier; \
	dict__overlying[@"isTopApp"] = @NO; \
    dict__overlying[@"rotationMode"] = @NO; \
    dict__overlying[@"hideStatusBarIfWanted"] = @YES; \
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.efrederickson.reachapp.beginresizing"), NULL, (__bridge CFDictionaryRef)dict__overlying, true);