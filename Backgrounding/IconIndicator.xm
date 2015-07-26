#import "RABackgrounder.h"
#import "RASettings.h"
#import "RAIconBadgeView.h"

NSMutableArray *managedIconViews = [NSMutableArray array];

@interface SBIconAccessoryImage : UIImage
-(id)initWithImage:(id)arg1 ;
@end

@interface SBDarkeningImageView : UIImageView
- (void)setImage:(id)arg1 brightness:(double)arg2;
- (void)setImage:(id)arg1;
@end

@interface SBIconBadgeView : UIView
{
    NSString *_text;
    _Bool _animating;
    id/*block*/ _queuedAnimation;
    _Bool _displayingAccessory;
    SBIconAccessoryImage *_backgroundImage;
    SBDarkeningImageView *_backgroundView;
    SBDarkeningImageView *_textView;
}

+ (id)_createImageForText:(id)arg1 highlighted:(_Bool)arg2;
+ (id)_checkoutImageForText:(id)arg1 highlighted:(_Bool)arg2;
+ (id)_checkoutBackgroundImage;
+ (id)checkoutAccessoryImagesForIcon:(id)arg1 location:(int)arg2;
+ (struct CGPoint)_overhang;
+ (double)_textPadding;
+ (struct CGPoint)_textOffset;
+ (double)_maxTextWidth;
+ (id)_textFont;
- (void)_resizeForTextImage:(id)arg1;
- (void)_clearText;
- (void)_zoomOutWithPreparation:(id/*block*/)arg1 animation:(id/*block*/)arg2 completion:(id/*block*/)arg3;
- (void)_zoomInWithTextImage:(id)arg1 preparation:(id/*block*/)arg2 animation:(id/*block*/)arg3 completion:(id/*block*/)arg4;
- (void)_crossfadeToTextImage:(id)arg1 withPreparation:(id/*block*/)arg2 animation:(id/*block*/)arg3 completion:(id/*block*/)arg4;
- (void)_configureAnimatedForText:(id)arg1 highlighted:(_Bool)arg2 withPreparation:(id/*block*/)arg3 animation:(id/*block*/)arg4 completion:(id/*block*/)arg5;
- (void)setAccessoryBrightness:(double)arg1;
- (struct CGPoint)accessoryOriginForIconBounds:(struct CGRect)arg1;
- (void)prepareForReuse;
- (_Bool)displayingAccessory;
- (void)configureForIcon:(id)arg1 location:(int)arg2 highlighted:(_Bool)arg3;
- (void)configureAnimatedForIcon:(id)arg1 location:(int)arg2 highlighted:(_Bool)arg3 withPreparation:(id/*block*/)arg4 animation:(id/*block*/)arg5 completion:(id/*block*/)arg6;
- (void)layoutSubviews;
- (void)dealloc;
- (id)init;
@end

@interface SBIconParallaxBadgeView : SBIconBadgeView
- (void)_applyParallaxSettings;
- (void)settings:(id)arg1 changedValueForKey:(id)arg2;
@end

#define SET_INFO_(x, y)    objc_setAssociatedObject(x, @selector(RA_setIndicatorViewInfo), [NSNumber numberWithInt:y], OBJC_ASSOCIATION_RETAIN_NONATOMIC)
#define GET_INFO_(x)       [objc_getAssociatedObject(x, @selector(RA_setIndicatorViewInfo)) intValue]
#define SET_INFO(y)        SET_INFO_(self, y)
#define GET_INFO           GET_INFO_(self)


NSString *stringFromIndicatorInfo(RAIconIndicatorViewInfo info)
{
	NSMutableString *ret = [[NSMutableString alloc] init];

	if (info & RAIconIndicatorViewInfoNone)
		return nil;

	if ([RASettings.sharedInstance showNativeStateIconIndicators] && (info & RAIconIndicatorViewInfoNative))
		[ret appendString:@"N"];
	
	if (info & RAIconIndicatorViewInfoForced)
		[ret appendString:@"F"];

	if (info & RAIconIndicatorViewInfoForceDeath)
		[ret appendString:@"D"];

	if (info & RAIconIndicatorViewInfoSuspendImmediately)
		[ret appendString:@"S"];
		
	if (info & RAIconIndicatorViewInfoUnkillable)
		[ret appendString:@"U"];

	if (info & RAIconIndicatorViewInfoUnlimitedBackgroundTime)
		[ret appendString:@"B"];

	return ret;
}

%hook SBIconView
%new -(void) RA_updateIndicatorView:(RAIconIndicatorViewInfo)info
{
	[[self viewWithTag:9962] removeFromSuperview];

	NSString *text = stringFromIndicatorInfo(info);
	if ((text == nil || text.length == 0) || (self.icon == nil || self.icon.application == nil || self.icon.application.isRunning == NO || ![RABackgrounder.sharedInstance shouldShowIndicatorForIdentifier:self.icon.application.bundleIdentifier]) || [RASettings.sharedInstance backgrounderEnabled] == NO)
	{
		[managedIconViews removeObject:self];
		return;
	}

	RAIconBadgeView *badge = (RAIconBadgeView*)[self viewWithTag:9962];
	if (!badge)
	{
		badge = [[RAIconBadgeView alloc] init];
		badge.tag = 9962;

		badge.textColor = UIColor.whiteColor;
		badge.textAlignment = NSTextAlignmentCenter;
		badge.clipsToBounds = YES;
		badge.layer.cornerRadius = 12;
		badge.backgroundColor = [UIColor colorWithRed:60/255.0f green:108/255.0f blue:255/255.0f alpha:1.0f];
	}

	badge.text = text;

	if (!badge.superview)
		[self addSubview:badge];

	CGPoint overhang = [%c(SBIconBadgeView) _overhang];
	badge.frame = CGRectMake(-overhang.x, -overhang.y, badge.frame.size.width, badge.frame.size.height);
	if ([managedIconViews containsObject:self] == NO)
		[managedIconViews addObject:self];
	SET_INFO(info);
}

%new -(void) RA_updateIndicatorViewWithExistingInfo
{
	if ([self viewWithTag:9962])
		[self RA_updateIndicatorView:GET_INFO];
}
%end

%hook SBApplication
- (void)setApplicationState:(unsigned int)arg1
{
    %orig;

    if (self.isRunning == NO)
    	[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:RAIconIndicatorViewInfoNone];

    //for (SBIconView *view in [managedIconViews copy])
    //	[view RA_updateIndicatorViewWithExistingInfo];
}
%end

%hook SBIconController
-(void)iconWasTapped:(SBApplicationIcon*)arg1 
{
	[RABackgrounder.sharedInstance updateIconIndicatorForIdentifier:arg1.application.bundleIdentifier withInfo:RAIconIndicatorViewInfoNone];
	%orig;
}
%end