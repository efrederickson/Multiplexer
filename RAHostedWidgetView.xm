#import "RAHostedWidgetView.h"
#import "RAWidgetBase.h"
#import "RAWidgetHostManager.h"

@interface RAHostedWidgetView () {
	RAWidgetBase *widget;
}
@end

@implementation RAHostedWidgetView
-(SBApplication*) app { return nil; }
-(NSString*) displayName { return [self loadWidget].displayName; }

//-(void) rotateToOrientation:(UIInterfaceOrientation)o;

-(RAWidgetBase*) loadWidget
{
	widget = [RAWidgetHostManager.sharedInstance widgetForIdentifier:self.bundleIdentifier];
	return widget;
}

-(void) preloadApp
{
	[self loadWidget];
}

-(void) loadApp
{
	widget.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
	[self addSubview:widget];
	[widget didAppear];
}

-(void) unloadApp
{
	[widget didDisappear];
	[widget removeFromSuperview];
}
@end