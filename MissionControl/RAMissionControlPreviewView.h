#import "headers.h"

@interface RAMissionControlPreviewView : UIImageView {
	SBIcon *icon;
	SBIconView *iconView;
}
@property (nonatomic, retain) SBApplication *application;

-(void) generatePreview;
-(void) generatePreviewAsync;
-(void) generateDesktopPreviewAsync:(id)desktop completion:(dispatch_block_t)completionBlock;
@end