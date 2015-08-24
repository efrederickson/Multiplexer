#import "RAThemeLoader.h"
#import "UIColor+HexString.h"
#import "headers.h"

#define COLOR(name) ([RAThemeLoader tryGetColorFromThemeImageName:name] ?: [UIColor RA_colorWithHexString:dict[name]])
//#define COLOR(name) [UIColor RA_colorWithHexString:dict[name]]

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
	ret.windowedMultaskingBarTitleTextAlignment = [RAThemeLoader getTextAlignment:dict[@"windowedMultaskingBarTitleTextAlignment"]];

	ret.windowedMultitaskingCloseButtonAlignment = [dict[@"windowedMultitaskingCloseButtonAlignment"] intValue];
	ret.windowedMultitaskingCloseButtonPriority = [dict[@"windowedMultitaskingCloseButtonPriority"] intValue];
	ret.windowedMultitaskingMaxButtonAlignment = [dict[@"windowedMultitaskingMaxButtonAlignment"] intValue];
	ret.windowedMultitaskingMaxButtonPriority = [dict[@"windowedMultitaskingMaxButtonPriority"] intValue];
	ret.windowedMultitaskingMinButtonAlignment = [dict[@"windowedMultitaskingMinButtonAlignment"] intValue];
	ret.windowedMultitaskingMinButtonPriority = [dict[@"windowedMultitaskingMinButtonPriority"] intValue];
	ret.windowedMultitaskingRotationAlignment = [dict[@"windowedMultitaskingRotationAlignment"] intValue];
	ret.windowedMultitaskingRotationPriority = [dict[@"windowedMultitaskingRotationPriority"] intValue];

	ret.windowedMultitaskingBarButtonCornerRadius = [dict[@"windowedMultitaskingBarButtonCornerType"] intValue];
	ret.windowedMultitaskingBarTitleTextInset = [dict[@"windowedMultitaskingBarTitleTextInset"] intValue];

	ret.windowedMultitaskingCloseIconOverlayColor = COLOR(@"windowedMultitaskingCloseIconOverlayColor") ?: ret.windowedMultitaskingCloseIconBackgroundColor;
	ret.windowedMultitaskingMaxIconOverlayColor = COLOR(@"windowedMultitaskingMaxIconOverlayColor") ?: ret.windowedMultitaskingMaxIconBackgroundColor;
	ret.windowedMultitaskingMinIconOverlayColor = COLOR(@"windowedMultitaskingMinIconOverlayColor") ?: ret.windowedMultitaskingMinIconBackgroundColor;
	ret.windowedMultitaskingRotationIconOverlayColor = COLOR(@"windowedMultitaskingRotationIconOverlayColor") ?: ret.windowedMultitaskingRotationIconBackgroundColor;

	ret.windowedMultitaskingBlurStyle = [dict[@"windowedMultitaskingBlurStyle"] intValue];
	ret.windowedMultitaskingOverlayColor = COLOR(@"windowedMultitaskingOverlayColor");

	ret.swipeOverDetachBarColor = COLOR(@"swipeOverDetachBarColor");

	ret.quickAccessUseGenericTabLabel = [dict objectForKey:@"quickAccessUseGenericTabLabel"] == nil ? NO : [dict[@"quickAccessUseGenericTabLabel"] boolValue];

	return ret;
}

+(NSTextAlignment) getTextAlignment:(NSObject*)value
{
	if ([value isKindOfClass:[NSString class]])
	{
		if ([value isEqual:@"NSTextAlignmentLeft"] || [value isEqual:@"0"] || [value isEqual:@"Left"])
			return NSTextAlignmentLeft;
		if ([value isEqual:@"NSTextAlignmentCenter"] || [value isEqual:@"1"] || [value isEqual:@"Center"])
			return NSTextAlignmentCenter;
		if ([value isEqual:@"NSTextAlignmentRight"] || [value isEqual:@"2"] || [value isEqual:@"Right"])
			return NSTextAlignmentRight;
		if ([value isEqual:@"NSTextAlignmentJustified"] || [value isEqual:@"3"] || [value isEqual:@"Justified"])
			return NSTextAlignmentJustified;
		if ([value isEqual:@"NSTextAlignmentNatural"] || [value isEqual:@"4"] || [value isEqual:@"Natural"])
			return NSTextAlignmentNatural;
	}
	else if ([value isKindOfClass:[NSNumber class]])
	{
		int actualValue = [((NSNumber*)value) intValue];
		if (actualValue == 0)
			return NSTextAlignmentLeft;
		else if (actualValue == 1)
			return NSTextAlignmentCenter;
		else if (actualValue == 2)
			return NSTextAlignmentRight;
		else if (actualValue == 3)
			return NSTextAlignmentJustified;
		else if (actualValue == 4)
			return NSTextAlignmentNatural;
	}
	return NSTextAlignmentCenter;
}

+(UIColor*) tryGetColorFromThemeImageName:(NSString*)name
{
	NSString *expandedPath = [NSString stringWithFormat:@"%@/ThemingImages/%@.png",RA_BASE_PATH,[[name lastPathComponent] stringByDeletingPathExtension]];
	BOOL exists = [NSFileManager.defaultManager fileExistsAtPath:expandedPath];
	if (!exists)
		return nil;
	UIImage *image = [UIImage imageWithContentsOfFile:expandedPath];
	if (image)
		return [UIColor colorWithPatternImage:image];
	return nil;
}
@end