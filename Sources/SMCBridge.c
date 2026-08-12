#include "SMCBridge.h"
#include <stdlib.h>
#include <string.h>
#include <IOKit/IOKitLib.h>

typedef struct {
    char                  major;
    char                  minor;
    char                  build;
    char                  reserved;
    short                 release;
} SMCKeyData_vers_t;

typedef struct {
    uint16_t              version;
    uint16_t              length;
    uint32_t              cpuPLimit;
    uint32_t              gpuPLimit;
    uint32_t              memPLimit;
} SMCKeyData_pLimitData_t;

typedef struct {
    uint32_t              dataSize;
    uint32_t              dataType;
    uint8_t               dataAttributes;
} SMCKeyData_keyInfo_t;

typedef struct {
    uint32_t              key;
    SMCKeyData_vers_t     vers;
    SMCKeyData_pLimitData_t pLimitData;
    SMCKeyData_keyInfo_t  keyInfo;
    uint8_t               result;
    uint8_t               status;
    uint8_t               data8;
    uint32_t              data32;
    uint8_t               bytes[32];
} SMCKeyData_t;

static uint32_t strToKey(const char *str) {
    return (uint32_t)str[0] << 24 | (uint32_t)str[1] << 16 | (uint32_t)str[2] << 8 | (uint32_t)str[3];
}

static void keyToStr(uint32_t key, char *str) {
    str[0] = (key >> 24) & 0xFF;
    str[1] = (key >> 16) & 0xFF;
    str[2] = (key >> 8) & 0xFF;
    str[3] = key & 0xFF;
    str[4] = '\0';
}

static double decodeFpe2(const uint8_t *bytes) {
    return (double)((int)bytes[0] << 6) + ((int)bytes[1] >> 2);
}

static double decodeFlt(const uint8_t *bytes) {
    float f;
    memcpy(&f, bytes, sizeof(float));
    return (double)f;
}

static int readSMCVal(io_connect_t conn, const char *keyStr, double *valOut) {
    SMCKeyData_t input, output;
    size_t size = sizeof(SMCKeyData_t);
    memset(&input, 0, size);
    memset(&output, 0, size);
    
    input.key = strToKey(keyStr);
    input.data8 = 9; // SMC_CMD_READ_KEYINFO
    
    if (IOConnectCallStructMethod(conn, 2, &input, size, &output, &size) != kIOReturnSuccess || output.result != 0) {
        return -1;
    }
    
    uint32_t dataSize = output.keyInfo.dataSize;
    uint32_t dataType = output.keyInfo.dataType;
    
    input.keyInfo.dataSize = dataSize;
    input.data8 = 5; // SMC_CMD_READ_BYTES
    
    if (IOConnectCallStructMethod(conn, 2, &input, size, &output, &size) != kIOReturnSuccess || output.result != 0) {
        return -1;
    }
    
    char typeStr[5];
    keyToStr(dataType, typeStr);
    
    if (strcmp(typeStr, "fpe2") == 0) {
        *valOut = decodeFpe2(output.bytes);
    } else if (strcmp(typeStr, "flt ") == 0) {
        *valOut = decodeFlt(output.bytes);
    } else if (strcmp(typeStr, "ui8 ") == 0) {
        *valOut = (double)output.bytes[0];
    } else {
        *valOut = (double)((int)output.bytes[0] << 8 | (int)output.bytes[1]);
    }
    return 0;
}

SMCFanData getSMCFanData(void) {
    SMCFanData fanData;
    memset(&fanData, 0, sizeof(fanData));
    
    io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
    if (!service) return fanData;
    
    io_connect_t conn = 0;
    if (IOServiceOpen(service, mach_task_self(), 0, &conn) != kIOReturnSuccess) {
        IOObjectRelease(service);
        return fanData;
    }
    
    double fans = 0;
    if (readSMCVal(conn, "FNum", &fans) == 0) {
        int numFans = (int)fans;
        if (numFans > 4) numFans = 4;
        fanData.count = numFans;
        for (int i = 0; i < numFans; i++) {
            char key[5];
            snprintf(key, sizeof(key), "F%dAc", i);
            double rpm = 0;
            if (readSMCVal(conn, key, &rpm) == 0) {
                fanData.fans[i].id = i;
                fanData.fans[i].rpm = (int)rpm;
            }
        }
    }
    
    IOServiceClose(conn);
    IOObjectRelease(service);
    return fanData;
}
