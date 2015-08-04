#import "RAWidgetHostManager.h"

@implementation RAWidgetHostManager
+(id) sharedInstance
{
	SHARED_INSTANCE2(RAWidgetHostManager, sharedInstance->widgets = [NSMutableArray array]);
}

-(void) addWidget:(RAWidgetBase*)widget
{
	if ([widgets containsObject:widget] == NO)
		[widgets addObject:widget];
}

-(void) removeWidget:(RAWidgetBase*)widget
{
	[self removeWidgetWithIdentifier:widget.identifier];
}

-(void) removeWidgetWithIdentifier:(NSString*)identifier
{
	for (RAWidgetBase *w in widgets)
	{
		if ([w.identifier isEqual:identifier])
		{
			[widgets removeObject:w];
			return;
		}
	}
}

-(RAWidgetBase*) widgetForIdentifier:(NSString*)identifier
{
	for (RAWidgetBase *w in widgets)
	{
		if ([w.identifier isEqual:identifier])
		{
			return w;
		}
	}
	return nil;
}
@end