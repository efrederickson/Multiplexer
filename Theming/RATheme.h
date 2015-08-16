#import <UIKit/UIKit.h>

@interface RATheme : NSObject

@property (nonatomic, retain) NSString *themeIdentifier;
@property (nonatomic, retain) NSString *themeName;

// Backgrounder
@property (nonatomic, retain) UIColor *backgroundingIndicatorBackgroundColor;
@property (nonatomic, retain) UIColor *backgroundingIndicatorTextColor;

// Mission Control
@property (nonatomic) int missionControlBlurStyle;
@property (nonatomic, retain) UIColor *missionControlScrollViewBackgroundColor;
@property (nonatomic) CGFloat missionControlScrollViewOpacity;
@property (nonatomic) CGFloat missionControlIconPreviewShadowRadius;

// Windowed Multitasking
@property (nonatomic, retain) UIColor *windowedMultitaskingWindowBarBackgroundColor;
@property (nonatomic, retain) UIColor *windowedMultitaskingCloseIconBackgroundColor;
@property (nonatomic, retain) UIColor *windowedMultitaskingCloseIconTint;
@property (nonatomic, retain) UIColor *windowedMultitaskingMaxIconBackgroundColor;
@property (nonatomic, retain) UIColor *windowedMultitaskingMaxIconTint;
@property (nonatomic, retain) UIColor *windowedMultitaskingMinIconBackgroundColor;
@property (nonatomic, retain) UIColor *windowedMultitaskingMinIconTint;
@property (nonatomic, retain) UIColor *windowedMultitaskingRotationIconBackgroundColor;
@property (nonatomic, retain) UIColor *windowedMultitaskingRotationIconTint;

@property (nonatomic, retain) UIColor *windowedMultitaskingBarTitleColor;

@property (nonatomic) int windowedMultitaskingCloseButtonAlignment;
@property (nonatomic) int windowedMultitaskingCloseButtonPriority;
@property (nonatomic) int windowedMultitaskingMaxButtonAlignment;
@property (nonatomic) int windowedMultitaskingMaxButtonPriority;
@property (nonatomic) int windowedMultitaskingMinButtonAlignment;
@property (nonatomic) int windowedMultitaskingMinButtonPriority;
@property (nonatomic) int windowedMultitaskingRotationAlignment;
@property (nonatomic) int windowedMultitaskingRotationPriority;

@property (nonatomic) int windowedMultitaskingBlurStyle;
@property (nonatomic, retain) UIColor *windowedMultitaskingOverlayColor;

// SwipeOver

@property (nonatomic, retain) UIColor *swipeOverDetachBarColor;
@end