#import "RARemoteKeyboardView.h"
#import "headers.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <Foundation/Foundation.h>
#import "RAMessagingServer.h"

@implementation RARemoteKeyboardView
@synthesize layerHost = _layerHost;

-(void) connectToKeyboardWindowForApp:(NSString*)identifier
{
	if (!identifier)
    {
        self.layerHost.contextId = 0;
		return;
    }
    _identifier = identifier;

    unsigned int value = [RAMessagingServer.sharedInstance getStoredKeyboardContextIdForApp:identifier];
    self.layerHost.contextId = value;
    
    NSLog(@"[ReachApp] loaded keyboard view with %d", value);
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        self.userInteractionEnabled = YES;
        self.layerHost = [[CALayerHost alloc] init];
        self.layerHost.anchorPoint = CGPointMake(0, 0);
        self.layerHost.transform = CATransform3DMakeScale(1/[UIScreen mainScreen].scale, 1/[UIScreen mainScreen].scale, 1);
        self.layerHost.bounds = self.bounds;
        [self.layer addSublayer:self.layerHost];
        update = NO;
    }
    
    return self;
}
-(void)dealloc
{
    self.layerHost = nil;
}
@end
