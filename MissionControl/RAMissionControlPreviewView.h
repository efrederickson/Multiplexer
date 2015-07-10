#import "headers.h"

@interface RAMissionControlPreviewView : UIImageView {
	SBIconView *iconView;
}
@property (nonatomic, retain) SBApplication *application;
-(void) generatePreview;
@end