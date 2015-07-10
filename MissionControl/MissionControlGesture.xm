#import "headers.h"
#import "RAMissionControlManager.h"
#import "RAGestureManager.h"

/*
%ctor
{
    [[RAGestureManager sharedInstance] addGestureRecognizer:^RAGestureCallbackResult(UIGestureRecognizerState state, CGPoint location) {
        if (state == UIGestureRecognizerStateBegan)
            [RAMissionControlManager.sharedInstance showMissionControl:YES]; 
        
        return RAGestureCallbackResultSuccess;
    } withCondition:^BOOL(CGPoint location) {
        return location.x >= 300 && ![[%c(SBLockScreenManager) sharedInstance] isUILocked];
    } forEdge:UIRectEdgeBottom identifier:@"com.efrederickson.reachapp.missioncontrol.systemgesture" priority:RAGesturePriorityDefault];
}
*/