#import "headers.h"

@interface RAMissionControlPreviewView : UIImageView {
	SBIcon *icon;
	SBIconView *iconView;
}
@property (nonatomic, retain) SBApplication *application;
-(void) generatePreview;
@end