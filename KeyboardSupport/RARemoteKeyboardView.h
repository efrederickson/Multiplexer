#import "headers.h"

@interface _UIRemoteView : UIView
@property (setter=_setActsAsTintView:, nonatomic) BOOL _actsAsTintView;
@property (setter=_setInheritsSecurity:, nonatomic) BOOL _inheritsSecurity;
@property (setter=_setStatusBarTintColor:, nonatomic, retain) UIColor *_statusBarTintColor;
@property (nonatomic, retain) NSObject* /*_UIHostedWindowHostingHandle*/ hostedWindowHostingHandle;
@property (nonatomic, copy) id /* block */ tintColorDidChangeHandler;

+ (BOOL)_requiresWindowTouches;
+ (Class)layerClass;
+ (id)viewWithHostedWindowHostingHandle:(id)arg1;
+ (id)viewWithRemoteContextID:(unsigned int)arg1;

- (BOOL)_actsAsTintView;
- (void)_compensateForGlobalMediaTimeAdjustmentsIfNecessary;
- (void)_didMoveFromWindow:(id)arg1 toWindow:(id)arg2;
- (id)_hitTest:(CGPoint)arg1 withEvent:(id)arg2 windowServerHitTestWindow:(id)arg3;
- (BOOL)_inheritsSecurity;
- (void)_setStatusBarTintColor:(id)arg1 duration:(double)arg2;
- (id)_statusBarTintColor;
- (void)applyTransformUndoingRemoteRootLayerTransform:(CGAffineTransform)arg1 frame:(CGRect)arg2;
- (void)dealloc;
- (id)hostedWindowHostingHandle;
- (void)setContextID:(unsigned int)arg1;
- (void)setTintColorDidChangeHandler:(id /* block */)arg1;
- (void)tintColorDidChange;
- (id /* block */)tintColorDidChangeHandler;
@end

@interface CALayerHost : CALayer
@property (nonatomic, assign) unsigned int contextId;
@end

@interface RARemoteKeyboardView : UIView {
	BOOL update;
	NSString *_identifier;
}
@property (nonatomic, retain) CALayerHost *layerHost;
-(void) connectToKeyboardWindowForApp:(NSString*)identifier;
@end
