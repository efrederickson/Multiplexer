#import "RADefaultWidgetSection.h"
#import "RAWidget.h"
#import "RAWidgetSectionManager.h"

@implementation RADefaultWidgetSection
+(id) sharedDefaultWidgetSection
{
	static RADefaultWidgetSection *section = nil;
	if (section == nil)
	{
		section = [[RADefaultWidgetSection alloc] init];
		[[RAWidgetSectionManager sharedInstance] registerSection:section];
	}
	return section;
}

-(NSString*) displayName 
{
	return @"Widgets";
}

-(NSString*) identifier 
{ 
	return @"com.efrederickson.reachapp.widgets.sections.default";
}
@end