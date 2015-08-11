// thank you based stackoverflow
// https://stackoverflow.com/questions/12475450/prevent-dispatch-after-background-task-from-being-executed

struct dispatch_async_handle {
    char didFire;       // control block did fire
    char shouldCall;    // control block should call payload
    char shouldFree;    // control block is owner of this handle
    char didFree;       // fix trying to free a freed dispatch_async_handle
};


#ifdef __cplusplus
extern "C"
#endif
struct dispatch_async_handle *dispatch_after_cancellable(dispatch_time_t when, dispatch_queue_t queue, dispatch_block_t payload);


#ifdef __cplusplus
extern "C"
#endif

void dispatch_after_cancel(struct dispatch_async_handle *handle);