#import <Foundation/Foundation.h>
#import "DLGMem.h"

__attribute__((constructor))
static void entry() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[[DLGMem alloc] init] launchDLGMem];
    });
}
