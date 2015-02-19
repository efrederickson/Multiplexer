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

static __attribute__((constructor)) void cant_believe_i_forgot_this_before()
{
	static id _widget = [[RADefaultWidgetSection alloc] init];
	[RAWidgetSectionManager.sharedInstance registerSection:_widget];
}