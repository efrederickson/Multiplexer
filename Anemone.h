// From: slack logs
// Usage to get icon badge:
// 
// @interface SBIconBadgeView
// + (SBIconAccessoryImage *)_checkoutBackgroundImage;
// @end
// 
// [UIImage imageNamed:@"SBBadgeBG.png"]
// 
// Notes:
// Can convert to UIColor with +[UIColor colorWithPatternImage:]
// Needs tested. Heard bad reports about colorWithPatternImage: and memory usage
// 

@interface ANEMSettingsManager : NSObject {
    NSArray *_themeSettings;
}
+ (instancetype)sharedManager;
- (NSArray *)themeSettings;
@end

#define HAS_ANEMONE (objc_getClass("ANEMSettingsManager") != nil)
