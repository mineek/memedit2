#ifndef il2cpp_types_h
#define il2cpp_types_h

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

typedef struct Il2CppDomain Il2CppDomain;
typedef struct Il2CppAssembly Il2CppAssembly;
typedef struct Il2CppImage Il2CppImage;
typedef struct Il2CppClass Il2CppClass;
typedef struct MethodInfo MethodInfo;
typedef struct FieldInfo FieldInfo;
typedef struct PropertyInfo PropertyInfo;
typedef struct EventInfo EventInfo;
typedef struct Il2CppType Il2CppType;
typedef struct Il2CppReflectionType Il2CppReflectionType;
typedef struct Il2CppReflectionMethod Il2CppReflectionMethod;

typedef uint16_t Il2CppChar;

typedef struct Il2CppObject {
    void* klass;
    void* monitor;
} Il2CppObject;

typedef struct Il2CppString {
    Il2CppObject object;
    int32_t length;
    Il2CppChar chars[0];
} Il2CppString;

typedef enum {
    IL2CPP_TYPE_END        = 0x00,
    IL2CPP_TYPE_VOID       = 0x01,
    IL2CPP_TYPE_BOOLEAN    = 0x02,
    IL2CPP_TYPE_CHAR       = 0x03,
    IL2CPP_TYPE_I1         = 0x04,
    IL2CPP_TYPE_U1         = 0x05,
    IL2CPP_TYPE_I2         = 0x06,
    IL2CPP_TYPE_U2         = 0x07,
    IL2CPP_TYPE_I4         = 0x08,
    IL2CPP_TYPE_U4         = 0x09,
    IL2CPP_TYPE_I8         = 0x0a,
    IL2CPP_TYPE_U8         = 0x0b,
    IL2CPP_TYPE_R4         = 0x0c,
    IL2CPP_TYPE_R8         = 0x0d,
    IL2CPP_TYPE_STRING     = 0x0e,
    IL2CPP_TYPE_PTR        = 0x0f,
    IL2CPP_TYPE_BYREF      = 0x10,
    IL2CPP_TYPE_VALUETYPE  = 0x11,
    IL2CPP_TYPE_CLASS      = 0x12,
    IL2CPP_TYPE_VAR        = 0x13,
    IL2CPP_TYPE_ARRAY      = 0x14,
    IL2CPP_TYPE_GENERICINST = 0x15,
    IL2CPP_TYPE_TYPEDBYREF = 0x16,
    IL2CPP_TYPE_I          = 0x18,
    IL2CPP_TYPE_U          = 0x19,
    IL2CPP_TYPE_FNPTR      = 0x1b,
    IL2CPP_TYPE_OBJECT     = 0x1c,
    IL2CPP_TYPE_SZARRAY    = 0x1d,
    IL2CPP_TYPE_MVAR       = 0x1e,
    IL2CPP_TYPE_CMOD_REQD  = 0x1f,
    IL2CPP_TYPE_CMOD_OPT   = 0x20,
    IL2CPP_TYPE_INTERNAL   = 0x21,
    IL2CPP_TYPE_MODIFIER   = 0x40,
    IL2CPP_TYPE_SENTINEL   = 0x41,
    IL2CPP_TYPE_PINNED     = 0x45,
    IL2CPP_TYPE_ENUM       = 0x55
} Il2CppTypeEnum;

#endif /* il2cpp_types_h */
