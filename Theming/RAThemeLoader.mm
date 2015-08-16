#import "RAThemeLoader.h"
#import "UIColor+HexString.h"
#import "headers.h"

#define COLOR(name) [UIColor RA_colorWithHexString:dict[name]]

@implementation RAThemeLoader
+(RATheme*)loadFromFile:(NSString*)baseName
{
	NSString *fullPath = [NSString stringWithFormat:@"%@/Themes/%@.plist",RA_BASE_PATH,[[baseName lastPathComponent] stringByDeletingPathExtension]];

	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:fullPath];
	return [RAThemeLoader themeFromDictionary:dict];
}

+(RATheme*) themeFromDictionary:(NSDictionary*)dict
{
	RATheme *ret = [[RATheme alloc] init];

	ret.themeIdentifier = dict[@"identifier"];
	ret.themeName = dict[@"displayName"];

	ret.backgroundingIndicatorBackgroundColor = COLOR(@"backgroundingIndicatorBackgroundColor");
	ret.backgroundingIndicatorTextColor = COLOR(@"backgroundingIndicatorTextColor");

	ret.missionControlBlurStyle = [dict[@"missionControlBlurStyle"] intValue];
	ret.missionControlScrollViewBackgroundColor = COLOR(@"missionControlScrollViewBackgroundColor");
	ret.missionControlScrollViewOpacity = [dict[@"missionControlScrollViewOpacity"] floatValue];
	ret.missionControlIconPreviewShadowRadius = [dict[@"missionControlIconPreviewShadowRadius"] floatValue];

	ret.windowedMultitaskingWindowBarBackgroundColor = COLOR(@"windowedMultitaskingWindowBarBackgroundColor");
	ret.windowedMultitaskingCloseIconBackgroundColor = COLOR(@"windowedMultitaskingCloseIconBackgroundColor");
	ret.windowedMultitaskingCloseIconTint = COLOR(@"windowedMultitaskingCloseIconTint");
	ret.windowedMultitaskingMaxIconBackgroundColor = COLOR(@"windowedMultitaskingMaxIconBackgroundColor");
	ret.windowedMultitaskingMaxIconTint = COLOR(@"windowedMultitaskingMaxIconTint");
	ret.windowedMultitaskingMinIconBackgroundColor = COLOR(@"windowedMultitaskingMinIconBackgroundColor");
	ret.windowedMultitaskingMinIconTint = COLOR(@"windowedMultitaskingMinIconTint");
	ret.windowedMultitaskingRotationIconBackgroundColor = COLOR(@"windowedMultitaskingRotationIconBackgroundColor");
	ret.windowedMultitaskingRotationIconTint = COLOR(@"windowedMultitaskingRotationIconTint");
	ret.windowedMultitaskingBarTitleColor = COLOR(@"windowedMultitaskingBarTitleColor");

	ret.windowedMultitaskingCloseButtonAlignment = [dict[@"windowedMultitaskingCloseButtonAlignment"] intValue];
	ret.windowedMultitaskingCloseButtonPriority = [dict[@"windowedMultitaskingCloseButtonPriority"] intValue];
	ret.windowedMultitaskingMaxButtonAlignment = [dict[@"windowedMultitaskingMaxButtonAlignment"] intValue];
	ret.windowedMultitaskingMaxButtonPriority = [dict[@"windowedMultitaskingMaxButtonPriority"] intValue];
	ret.windowedMultitaskingMinButtonAlignment = [dict[@"windowedMultitaskingMinButtonAlignment"] intValue];
	ret.windowedMultitaskingMinButtonPriority = [dict[@"windowedMultitaskingMinButtonPriority"] intValue];
	ret.windowedMultitaskingRotationAlignment = [dict[@"windowedMultitaskingRotationAlignment"] intValue];
	ret.windowedMultitaskingRotationPriority = [dict[@"windowedMultitaskingRotationPriority"] intValue];

	ret.windowedMultitaskingBlurStyle = [dict[@"windowedMultitaskingBlurStyle"] intValue];
	ret.windowedMultitaskingOverlayColor = COLOR(@"windowedMultitaskingOverlayColor");

	ret.swipeOverDetachBarColor = COLOR(@"swipeOverDetachBarColor");

	return ret;
}
@end