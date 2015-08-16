#import "headers.h"

@interface RAMissionControlPreviewView : UIImageView {
	SBIcon *icon;
	SBIconView *iconView;
}
@property (nonatomic, retain) SBApplication *application;
@property (nonatomic, retain) UIImage *originalImage;
-(void) generatePreview;
@end