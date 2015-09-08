#import <UIKit/UIKit.h>

struct RAMessageAppData {
	BOOL shouldForceSize;
	// Can't use CGSize because it uses CGFloats which aren't able to be transferred between 32/64bit processes
	// Also why it can't use CGFloat
	float wantedClientOriginX;
	float wantedClientOriginY;
	float wantedClientWidth;
	float wantedClientHeight;
	BOOL statusBarVisibility;
	BOOL shouldForceStatusBar;
	BOOL canHideStatusBarIfWanted;
	UIInterfaceOrientation forcedOrientation;
	BOOL shouldForceOrientation;
	BOOL shouldUseExternalKeyboard;
	BOOL isBeingHosted;
	BOOL forcePhoneMode; // Requires client restart to apply
};

typedef void (^RAMessageCompletionCallback)(BOOL success);
