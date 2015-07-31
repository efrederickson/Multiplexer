#import "RADefaultWidgetSection.h"
#import "RAWidget.h"
#import "RAWidgetSectionManager.h"
#import "headers.h"

@implementation RADefaultWidgetSection
+(id) sharedDefaultWidgetSection
{
	SHARED_INSTANCE2(RADefaultWidgetSection, [[RAWidgetSectionManager sharedInstance] registerSection:sharedInstance]);
}

-(NSString*) displayName 
{
	return LOCALIZE(@"WIDGETS");
}

-(NSString*) identifier 
{ 
	return @"com.efrederickson.reachapp.widgets.sections.default";
}
@end

static __attribute__((constructor)) void cant_believe_i_forgot_this_before()
{
	static id _widget = [RADefaultWidgetSection sharedDefaultWidgetSection];
	[RAWidgetSectionManager.sharedInstance registerSection:_widget];
}