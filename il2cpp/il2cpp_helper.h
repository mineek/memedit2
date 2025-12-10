#ifndef il2cpp_helper_h
#define il2cpp_helper_h

#include "il2cpp_api.h"

typedef struct {
    Il2CppClass* klass;
    char* name;
    char* namespace;
    char* full_name;
} Il2CppClassInfo;

typedef struct {
    const MethodInfo* method;
    char* name;
    char* return_type;
    char* signature;
    int param_count;
    bool is_static;
} Il2CppMethodInfo;

typedef struct {
    Il2CppClassInfo* classes;
    int class_count;
} Il2CppEnumResult;

typedef struct {
    Il2CppMethodInfo* methods;
    int method_count;
} Il2CppMethodEnumResult;

bool il2cpp_helper_init(void);

// in all assemblies
Il2CppEnumResult* il2cpp_enumerate_classes(void);
void il2cpp_free_enum_result(Il2CppEnumResult* result);

// in a specific class
Il2CppMethodEnumResult* il2cpp_enumerate_methods(Il2CppClass* klass);
void il2cpp_free_method_enum_result(Il2CppMethodEnumResult* result);

Il2CppEnumResult* il2cpp_search_classes(const char* search_term);
Il2CppMethodEnumResult* il2cpp_search_methods(Il2CppClass* klass, const char* search_term);

const char* il2cpp_get_type_name(const Il2CppType* type);
char* il2cpp_get_method_signature(const MethodInfo* method);

typedef struct {
    FieldInfo* field;
    char* name;
    char* type_name;
    int type_enum;
    bool is_static;
    size_t offset;
} Il2CppFieldInfo;

typedef struct {
    void* instance;
} Il2CppInstanceInfo;

typedef struct {
    Il2CppFieldInfo* fields;
    int field_count;
} Il2CppFieldEnumResult;

typedef struct {
    Il2CppInstanceInfo* instances;
    int instance_count;
} Il2CppInstanceEnumResult;

typedef struct {
    const Il2CppType* type;
    char* type_name;
    char* param_name;
    int type_enum;
} Il2CppParamInfo;

Il2CppParamInfo* il2cpp_get_method_params(const MethodInfo* method, int* param_count);
void il2cpp_free_param_info(Il2CppParamInfo* params, int param_count);
char* il2cpp_invoke_method(const MethodInfo* method, void* obj, void** params);

Il2CppFieldEnumResult* il2cpp_enumerate_fields(Il2CppClass* klass);
void il2cpp_free_field_enum_result(Il2CppFieldEnumResult* result);

char* il2cpp_get_field_value_string(void* obj, FieldInfo* field, Il2CppClass* klass);

bool il2cpp_set_field_value_from_string(void* obj, FieldInfo* field, Il2CppClass* klass, const char* value, int type_enum);

bool il2cpp_can_edit_field_type(int type_enum);

Il2CppInstanceEnumResult* il2cpp_find_instances(Il2CppClass* klass);
void il2cpp_free_instance_enum_result(Il2CppInstanceEnumResult* result);

#endif /* il2cpp_helper_h */
