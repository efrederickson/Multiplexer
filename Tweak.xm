#define MULTIPLEXER_CORE 1
#import "headers.h"

/*
This project thanks: 
ForceReach: https://github.com/PoomSmart/ForceReach/
Reference: https://github.com/fewjative/Reference
MessageBox: https://github.com/b3ll/MessageBox
This pastie (by @Freerunnering?): http://pastie.org/pastes/8684110
Previous research done by b3ll and freerunnering (with _UIRemoteView, BKSProcessAssertion, etc)
Various tips and help (early ReachApp (when it was just the reachability part): @sharedRoutine
Various concepts / help / ideas: Ethan Arbuckle (@its_not_herpes)

Many concepts and ideas have been used from them.
Unlike shinvou's claims, however, there was no copyright violation. Nor did I use any of his code. Or Auxo 3's for that matter. See here for context: https://www.reddit.com/r/jailbreak/comments/3esp30/question_how_come_we_all_desperately_waited_for/cti3eck
Any code based off of or using parts of the above projects is documented. 

*/

// IS_SPRINGBOARD macro optimized from always comparing NSBundle - because it won't change in-process
BOOL $__IS_SPRINGBOARD = NO;
%ctor 
{
	$__IS_SPRINGBOARD = [NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"];
}

void SET_BACKGROUNDED(id settings, BOOL value)
{
#if __has_feature(objc_arc)
	// stupid ARC...
    ptrdiff_t bgOffset = ivar_getOffset(class_getInstanceVariable([settings class], "_backgrounded"));
    char *bgPtr = ((char *)(__bridge void *)settings) + bgOffset;
    memcpy(bgPtr, &value, sizeof(value));
#else
	// ARC is off, easy way
	if (value)
		object_setInstanceVariable(settings, "_backgrounded", (void*)YES); // strangely it doesn't like using the val, i have to do this.
	else
		object_setInstanceVariable(settings, "_backgrounded", (void*)NO);
#endif
}

/*
#if DEBUG
//extern "C" void _CFEnableZombies(void);
%ctor
{
    IF_SPRINGBOARD {
        _CFEnableZombies();
    }
}
#endif
*/