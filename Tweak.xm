#import "headers.h"

/*
This code thanks: 
ForceReach: https://github.com/PoomSmart/ForceReach/
Reference: https://github.com/fewjative/Reference
MessageBox: https://github.com/b3ll/MessageBox
This pastie (by @Freerunnering?): http://pastie.org/pastes/8684110
Various tips and help: @sharedRoutine
Various concepts and help: Ethan Arbuckle (@its_not_herpes)

Many concepts and ideas have been used from them.
*/

void SET_BACKGROUNDED(id settings, BOOL val)
{
#if __has_feature(objc_arc)
	// stupid ARC. 
    BOOL value = val; // just used for a pointer later. 
    ptrdiff_t bgOffset = ivar_getOffset(class_getInstanceVariable([settings class], "_backgrounded"));
    char *bgPtr = ((char *)(__bridge void *)settings) + bgOffset;
    memcpy(bgPtr, &value, sizeof(value));
#else
	// ARC is off, easy way
	if (val)
		object_setInstanceVariable(settings, "_backgrounded", (void*)YES);
	else
		object_setInstanceVariable(settings, "_backgrounded", (void*)NO);
#endif
}