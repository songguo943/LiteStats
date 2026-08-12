#ifndef SMCBridge_h
#define SMCBridge_h

#include <stdio.h>

typedef struct {
    int id;
    int rpm;
} SMCFanItem;

typedef struct {
    int count;
    SMCFanItem fans[4];
} SMCFanData;

#ifdef __cplusplus
extern "C" {
#endif

SMCFanData getSMCFanData(void);

#ifdef __cplusplus
}
#endif

#endif /* SMCBridge_h */
