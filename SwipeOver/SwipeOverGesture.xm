#import "RAGestureManager.h"
#import "RASwipeOverManager.h"
#import "RAKeyboardStateListener.h"
#import "RAMissionControlManager.h"
#import "PDFImage.h"
#import "PDFImageOptions.h"
#import "RASettings.h"
#import "RAHostManager.h"

UIView *grabberView;
BOOL isShowingGrabber = NO;
BOOL isPastGrabber = NO;
NSDate *lastTouch;
CGPoint startingPoint;

CGRect adjustFrameForRotation()
{
    CGFloat portraitWidth = 30;
    CGFloat portraitHeight = 50;

    CGFloat width = UIScreen.mainScreen._interfaceOrientedBounds.size.width;
    CGFloat height = UIScreen.mainScreen._interfaceOrientedBounds.size.height;

    switch ([[UIApplication.sharedApplication _accessibilityFrontMostApplication] statusBarOrientation])
    {
        case UIInterfaceOrientationPortrait:
            NSLog(@"[ReachApp] portrait");
            return (CGRect){ { width - portraitWidth + 5, (height - portraitHeight) / 2 }, { portraitWidth, portraitHeight } };
        case UIInterfaceOrientationPortraitUpsideDown:
            NSLog(@"[ReachApp] portrait upside down");
            return (CGRect){ { 0, 0}, { 50, 50 } };
        case UIInterfaceOrientationLandscapeLeft:
            NSLog(@"[ReachApp] landscape left");
            return (CGRect){ { ((height - portraitWidth) / 2), -(portraitWidth / 2) }, { portraitWidth, portraitHeight } };
        case UIInterfaceOrientationLandscapeRight:
            NSLog(@"[ReachApp] landscape right");
            return (CGRect){ { (height - portraitHeight) / 2, width - portraitWidth - 5 }, { portraitWidth, portraitHeight } };
    }
    return CGRectZero;
}

CGAffineTransform adjustTransformRotation()
{    
    switch ([[UIApplication.sharedApplication _accessibilityFrontMostApplication] statusBarOrientation])
    {
        case UIInterfaceOrientationPortrait:
            return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(0));
        case UIInterfaceOrientationPortraitUpsideDown:
            return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
        case UIInterfaceOrientationLandscapeLeft:
            return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-90));
        case UIInterfaceOrientationLandscapeRight:
            return CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90));
    }
    return CGAffineTransformIdentity;
}

BOOL swipeOverLocationIsInValidArea(CGFloat y)
{
    if (y == 0) return YES; // more than likely, UIGestureRecognizerStateEnded

    switch ([RASettings.sharedInstance swipeOverGrabArea])
    {
        case RAGrabAreaSideAnywhere:
            return YES;
        case RAGrabAreaSideTopThird:
            return y <= UIScreen.mainScreen._interfaceOrientedBounds.size.height / 3.0;
        case RAGrabAreaSideMiddleThird:
            return y >= UIScreen.mainScreen._interfaceOrientedBounds.size.height / 3.0 && y <= (UIScreen.mainScreen._interfaceOrientedBounds.size.height / 3.0) * 2;
        case RAGrabAreaSideBottomThird:
            return y >= (UIScreen.mainScreen._interfaceOrientedBounds.size.height / 3.0) * 2;
        default:
            return NO;
    }
}

%ctor
{
    [[RAGestureManager sharedInstance] addGestureRecognizer:^RAGestureCallbackResult(UIGestureRecognizerState state, CGPoint location, CGPoint velocity) {
        lastTouch = [NSDate date];

        if ([[%c(SBUIController) sharedInstance] shouldShowControlCenterTabControlOnFirstSwipe] || [RASettings.sharedInstance alwaysShowSOGrabber])
        {
            if (isShowingGrabber == NO && isPastGrabber == NO)
            {
                isShowingGrabber = YES;

                grabberView = [[UIView alloc] init];

                _UIBackdropView *bgView = [[%c(_UIBackdropView) alloc] initWithStyle:1];
                bgView.frame = CGRectMake(0, 0, grabberView.frame.size.width, grabberView.frame.size.height);
                [grabberView addSubview:bgView];

                //grabberView.backgroundColor = UIColor.redColor;
                grabberView.frame = adjustFrameForRotation();

                UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, grabberView.frame.size.width - 20, grabberView.frame.size.height - 20)];
                imgView.image = [[PDFImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Grabber.pdf",RA_BASE_PATH]] imageWithOptions:[PDFImageOptions optionsWithSize:CGSizeMake(grabberView.frame.size.width - 20, grabberView.frame.size.height - 20)]];
                [grabberView addSubview:imgView];
                grabberView.layer.cornerRadius = 5;
                grabberView.clipsToBounds = YES;

                grabberView.transform = adjustTransformRotation();
                //[UIWindow.keyWindow addSubview:grabberView]; // The desktop view most likely
                [[[RAHostManager systemHostViewForApplication:UIApplication.sharedApplication._accessibilityFrontMostApplication] superview] addSubview:grabberView];

                static void (^dismisser)() = ^{ // top kek, needs "static" so it's not a local, self-retaining block
                    if ([[NSDate date] timeIntervalSinceDate:lastTouch] > 2)
                    {
                        [UIView animateWithDuration:0.2 animations:^{
                            grabberView.frame = CGRectOffset(grabberView.frame, 40, 0);
                        } completion:^(BOOL _) {
                            [grabberView removeFromSuperview];
                            grabberView = nil;
                            isShowingGrabber = NO;
                            isPastGrabber = NO;
                        }];
                    }
                    else if (grabberView) // left there
                    {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            dismisser();
                        });
                    }
                };
                dismisser();

                return RAGestureCallbackResultSuccess;
            }
            else if (CGRectContainsPoint(grabberView.frame, location))
            {
                [grabberView removeFromSuperview];
                grabberView = nil;
                isShowingGrabber = NO;
                isPastGrabber = YES;
            }
            else if (isPastGrabber == NO)
            {
                startingPoint = CGPointZero;
                isPastGrabber = NO;
                return RAGestureCallbackResultSuccess;
            }
        }

        CGPoint translation;
        switch (state) {
            case UIGestureRecognizerStateBegan:
                startingPoint = location;
                break;
            case UIGestureRecognizerStateChanged:
                translation = CGPointMake(location.x - startingPoint.x, location.y - startingPoint.y);
                break;
            case UIGestureRecognizerStateEnded:
                startingPoint = CGPointZero;
                isPastGrabber = NO;
                break;
        }

        if (![RASwipeOverManager.sharedInstance isUsingSwipeOver])
            [RASwipeOverManager.sharedInstance startUsingSwipeOver];
        
        if (state == UIGestureRecognizerStateChanged)
            [RASwipeOverManager.sharedInstance sizeViewForTranslation:translation state:state];

        return RAGestureCallbackResultSuccess;
    } withCondition:^BOOL(CGPoint location, CGPoint velocity) {
        if (RAKeyboardStateListener.sharedInstance.visible)
        {
            CGRect realKBFrame = CGRectMake(0, UIScreen.mainScreen._interfaceOrientedBounds.size.height, RAKeyboardStateListener.sharedInstance.size.width, RAKeyboardStateListener.sharedInstance.size.height);
            realKBFrame = CGRectOffset(realKBFrame, 0, -realKBFrame.size.height);

            if (CGRectContainsPoint(realKBFrame, location))
                return NO;
        }
        
        return [RASettings.sharedInstance swipeOverEnabled] && ![[%c(SBLockScreenManager) sharedInstance] isUILocked] && ![[%c(SBUIController) sharedInstance] isAppSwitcherShowing] && ![[%c(SBNotificationCenterController) sharedInstance] isVisible] && !RAMissionControlManager.sharedInstance.isShowingMissionControl && swipeOverLocationIsInValidArea(location.y);
    } forEdge:UIRectEdgeRight identifier:@"com.efrederickson.reachapp.swipeover.systemgesture" priority:RAGesturePriorityDefault];
}