#include "dispatch_after_cancel.h"

struct dispatch_async_handle *dispatch_after_cancellable(dispatch_time_t when, dispatch_queue_t queue, dispatch_block_t payload)
{
    struct dispatch_async_handle *handle = malloc(sizeof(struct dispatch_async_handle));

    handle->didFire = 0;
    handle->shouldCall = 1; // initially, payload should be called
    handle->shouldFree = 0; // and handles belong to owner

    dispatch_after(when, queue, ^{

        //NSLog(@"[ReachApp][%p] (control block) call=%d, free=%d, didfree=%d", handle, handle->shouldCall, handle->shouldFree, handle->didFree);

        handle->didFire = 1;
        if (handle->shouldCall) payload();
        if (handle->shouldFree && handle->didFree == 0) free(handle);
    });

    return handle; // to owner
}

void dispatch_after_cancel(struct dispatch_async_handle *handle)
{
    if (handle->didFire && handle->shouldFree == 0) {
        //printf("[%p] (owner) too late, freeing myself\n", handle);
        handle->didFree = 1;
        free(handle);
    }
    else {
        //printf("[%p] (owner) set call=0, free=1\n", handle);
        handle->shouldCall = 0;
        handle->shouldFree = 1; // control block is owner now
    }
}