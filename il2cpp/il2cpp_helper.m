#include "il2cpp_helper.h"
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <stdio.h>

#import <Foundation/Foundation.h>
#import "../RemoteLog.h"
#define IL2CPP_LOG(...) RLog(__VA_ARGS__)

bool il2cpp_helper_init(void) {
    return il2cpp_api_init();
}

const char* il2cpp_get_type_name(const Il2CppType* type) {
    if (!type || !il2cpp_type_get_type) return "unknown";

    if (il2cpp_type_get_name) {
        char* name = il2cpp_type_get_name(type);
        if (name) return name;
    }

    int type_enum = il2cpp_type_get_type(type);
    switch (type_enum) {
        case IL2CPP_TYPE_VOID: return "void";
        case IL2CPP_TYPE_BOOLEAN: return "bool";
        case IL2CPP_TYPE_CHAR: return "char";
        case IL2CPP_TYPE_I1: return "sbyte";
        case IL2CPP_TYPE_U1: return "byte";
        case IL2CPP_TYPE_I2: return "short";
        case IL2CPP_TYPE_U2: return "ushort";
        case IL2CPP_TYPE_I4: return "int";
        case IL2CPP_TYPE_U4: return "uint";
        case IL2CPP_TYPE_I8: return "long";
        case IL2CPP_TYPE_U8: return "ulong";
        case IL2CPP_TYPE_R4: return "float";
        case IL2CPP_TYPE_R8: return "double";
        case IL2CPP_TYPE_STRING: return "string";
        case IL2CPP_TYPE_OBJECT: return "object";
        default: return "unknown";
    }
}

char* il2cpp_get_method_signature(const MethodInfo* method) {
    if (!method) return strdup("invalid");

    const char* method_name = il2cpp_method_get_name(method);
    if (!method_name) method_name = "unknown";

    const Il2CppType* return_type = il2cpp_method_get_return_type(method);
    const char* return_type_name = il2cpp_get_type_name(return_type);

    uint32_t param_count = il2cpp_method_get_param_count ? il2cpp_method_get_param_count(method) : 0;

    // Build signature string
    char signature[512];
    snprintf(signature, sizeof(signature), "%s %s(", return_type_name, method_name);

    for (uint32_t i = 0; i < param_count; i++) {
        if (il2cpp_method_get_param) {
            const Il2CppType* param_type = il2cpp_method_get_param(method, i);
            const char* param_type_name = il2cpp_get_type_name(param_type);

            const char* param_name = "";
            if (il2cpp_method_get_param_name) {
                param_name = il2cpp_method_get_param_name(method, i);
                if (!param_name) param_name = "";
            }

            if (i > 0) strlcat(signature, ", ", sizeof(signature));
            strlcat(signature, param_type_name, sizeof(signature));
            if (strlen(param_name) > 0) {
                strlcat(signature, " ", sizeof(signature));
                strlcat(signature, param_name, sizeof(signature));
            }
        }
    }

    strlcat(signature, ")", sizeof(signature));
    return strdup(signature);
}

Il2CppEnumResult* il2cpp_enumerate_classes(void) {
    if (!il2cpp_api_is_available()) {
        IL2CPP_LOG(@"enumerate_classes: IL2CPP API not available");
        return NULL;
    }

    Il2CppDomain* domain = il2cpp_domain_get();
    if (!domain) {
        IL2CPP_LOG(@"enumerate_classes: Failed to get domain!");
        return NULL;
    }
    IL2CPP_LOG(@"enumerate_classes: Got domain: %p", domain);

    size_t assembly_count = 0;
    const Il2CppAssembly** assemblies = il2cpp_domain_get_assemblies(domain, &assembly_count);
    if (!assemblies) {
        IL2CPP_LOG(@"enumerate_classes: Failed to get assemblies!");
        return NULL;
    }

    IL2CPP_LOG(@"enumerate_classes: Found %zu assemblies", assembly_count);

    // count total classes
    int total_class_count = 0;
    IL2CPP_LOG(@"enumerate_classes: Counting classes in assemblies");
    for (size_t i = 0; i < assembly_count; i++) {
        const Il2CppImage* image = il2cpp_assembly_get_image(assemblies[i]);
        if (image && il2cpp_image_get_class_count) {
            size_t count = il2cpp_image_get_class_count(image);
            total_class_count += count;
        }
    }

    IL2CPP_LOG(@"enumerate_classes: Total classes: %d", total_class_count);

    Il2CppEnumResult* result = (Il2CppEnumResult*)malloc(sizeof(Il2CppEnumResult));
    result->classes = (Il2CppClassInfo*)malloc(sizeof(Il2CppClassInfo) * total_class_count);
    result->class_count = 0;

    for (size_t i = 0; i < assembly_count; i++) {
        const Il2CppImage* image = il2cpp_assembly_get_image(assemblies[i]);
        if (!image) continue;

        const char* image_name = il2cpp_image_get_name(image);
        size_t class_count = il2cpp_image_get_class_count ? il2cpp_image_get_class_count(image) : 0;

        for (size_t j = 0; j < class_count; j++) {
            Il2CppClass* klass = (Il2CppClass*)il2cpp_image_get_class(image, j);
            if (!klass) continue;

            const char* name = il2cpp_class_get_name(klass);
            const char* namespace = il2cpp_class_get_namespace(klass);

            if (!name) name = "<unknown>";
            if (!namespace) namespace = "";

            Il2CppClassInfo* info = &result->classes[result->class_count];
            info->klass = klass;
            info->name = strdup(name);
            info->namespace = strdup(namespace);

            // build full name
            if (strlen(namespace) > 0) {
                char full_name[512];
                snprintf(full_name, sizeof(full_name), "%s.%s", namespace, name);
                info->full_name = strdup(full_name);
            } else {
                info->full_name = strdup(name);
            }

            result->class_count++;
        }
    }

    return result;
}

void il2cpp_free_enum_result(Il2CppEnumResult* result) {
    if (!result) return;

    for (int i = 0; i < result->class_count; i++) {
        free(result->classes[i].name);
        free(result->classes[i].namespace);
        free(result->classes[i].full_name);
    }

    free(result->classes);
    free(result);
}

Il2CppMethodEnumResult* il2cpp_enumerate_methods(Il2CppClass* klass) {
    if (!klass || !il2cpp_class_get_methods) return NULL;

    // Count methods first
    int method_count = 0;
    void* iter = NULL;
    while (il2cpp_class_get_methods(klass, &iter)) {
        method_count++;
    }

    Il2CppMethodEnumResult* result = (Il2CppMethodEnumResult*)malloc(sizeof(Il2CppMethodEnumResult));
    result->methods = (Il2CppMethodInfo*)malloc(sizeof(Il2CppMethodInfo) * method_count);
    result->method_count = 0;

    iter = NULL;
    const MethodInfo* method;
    while ((method = il2cpp_class_get_methods(klass, &iter))) {
        Il2CppMethodInfo* info = &result->methods[result->method_count];

        info->method = method;

        const char* name = il2cpp_method_get_name(method);
        info->name = strdup(name ? name : "<unknown>");

        const Il2CppType* return_type = il2cpp_method_get_return_type(method);
        const char* return_type_name = il2cpp_get_type_name(return_type);
        info->return_type = strdup(return_type_name);

        info->signature = il2cpp_get_method_signature(method);

        info->param_count = il2cpp_method_get_param_count ? il2cpp_method_get_param_count(method) : 0;

        bool is_instance = il2cpp_method_is_instance ? il2cpp_method_is_instance(method) : true;
        info->is_static = !is_instance;

        result->method_count++;
    }

    return result;
}

void il2cpp_free_method_enum_result(Il2CppMethodEnumResult* result) {
    if (!result) return;

    for (int i = 0; i < result->method_count; i++) {
        free(result->methods[i].name);
        free(result->methods[i].return_type);
        free(result->methods[i].signature);
    }

    free(result->methods);
    free(result);
}

Il2CppEnumResult* il2cpp_search_classes(const char* search_term) {
    if (!search_term) return NULL;

    Il2CppEnumResult* all_classes = il2cpp_enumerate_classes();
    if (!all_classes) return NULL;

    // Count matching classes
    int match_count = 0;
    for (int i = 0; i < all_classes->class_count; i++) {
        if (strcasestr(all_classes->classes[i].full_name, search_term) ||
            strcasestr(all_classes->classes[i].name, search_term)) {
            match_count++;
        }
    }

    Il2CppEnumResult* result = (Il2CppEnumResult*)malloc(sizeof(Il2CppEnumResult));
    result->classes = (Il2CppClassInfo*)malloc(sizeof(Il2CppClassInfo) * match_count);
    result->class_count = 0;

    // Copy matching classes
    for (int i = 0; i < all_classes->class_count; i++) {
        if (strcasestr(all_classes->classes[i].full_name, search_term) ||
            strcasestr(all_classes->classes[i].name, search_term)) {
            Il2CppClassInfo* info = &result->classes[result->class_count];
            info->klass = all_classes->classes[i].klass;
            info->name = strdup(all_classes->classes[i].name);
            info->namespace = strdup(all_classes->classes[i].namespace);
            info->full_name = strdup(all_classes->classes[i].full_name);
            result->class_count++;
        }
    }

    il2cpp_free_enum_result(all_classes);
    return result;
}

Il2CppMethodEnumResult* il2cpp_search_methods(Il2CppClass* klass, const char* search_term) {
    if (!klass || !search_term) return NULL;

    Il2CppMethodEnumResult* all_methods = il2cpp_enumerate_methods(klass);
    if (!all_methods) return NULL;

    // Count matching methods
    int match_count = 0;
    for (int i = 0; i < all_methods->method_count; i++) {
        if (strcasestr(all_methods->methods[i].name, search_term) ||
            strcasestr(all_methods->methods[i].signature, search_term)) {
            match_count++;
        }
    }

    Il2CppMethodEnumResult* result = (Il2CppMethodEnumResult*)malloc(sizeof(Il2CppMethodEnumResult));
    result->methods = (Il2CppMethodInfo*)malloc(sizeof(Il2CppMethodInfo) * match_count);
    result->method_count = 0;

    // Copy matching methods
    for (int i = 0; i < all_methods->method_count; i++) {
        if (strcasestr(all_methods->methods[i].name, search_term) ||
            strcasestr(all_methods->methods[i].signature, search_term)) {
            Il2CppMethodInfo* info = &result->methods[result->method_count];
            info->method = all_methods->methods[i].method;
            info->name = strdup(all_methods->methods[i].name);
            info->return_type = strdup(all_methods->methods[i].return_type);
            info->signature = strdup(all_methods->methods[i].signature);
            info->param_count = all_methods->methods[i].param_count;
            info->is_static = all_methods->methods[i].is_static;
            result->method_count++;
        }
    }

    il2cpp_free_method_enum_result(all_methods);
    return result;
}

Il2CppParamInfo* il2cpp_get_method_params(const MethodInfo* method, int* param_count) {
    if (!method || !param_count) return NULL;

    *param_count = il2cpp_method_get_param_count ? il2cpp_method_get_param_count(method) : 0;
    if (*param_count == 0) return NULL;

    Il2CppParamInfo* params = (Il2CppParamInfo*)malloc(sizeof(Il2CppParamInfo) * (*param_count));

    for (int i = 0; i < *param_count; i++) {
        const Il2CppType* type = il2cpp_method_get_param ? il2cpp_method_get_param(method, i) : NULL;
        params[i].type = type;

        const char* type_name = il2cpp_get_type_name(type);
        params[i].type_name = strdup(type_name ? type_name : "unknown");

        const char* param_name = "";
        if (il2cpp_method_get_param_name) {
            param_name = il2cpp_method_get_param_name(method, i);
            if (!param_name) param_name = "";
        }
        params[i].param_name = strdup(param_name);

        params[i].type_enum = il2cpp_type_get_type ? il2cpp_type_get_type(type) : 0;
    }

    return params;
}

void il2cpp_free_param_info(Il2CppParamInfo* params, int param_count) {
    if (!params) return;

    for (int i = 0; i < param_count; i++) {
        free(params[i].type_name);
        free(params[i].param_name);
    }
    free(params);
}

char* il2cpp_invoke_method(const MethodInfo* method, void* obj, void** params) {
    if (!method || !il2cpp_runtime_invoke) {
        IL2CPP_LOG(@"invoke_method: Invalid method or runtime_invoke not available");
        return NULL;
    }

    IL2CPP_LOG(@"invoke_method: Invoking method %s", il2cpp_method_get_name(method));

    // actual invocation
    Il2CppObject* exception = NULL;
    Il2CppObject* result = il2cpp_runtime_invoke(method, obj, params, &exception);

    if (exception) {
        IL2CPP_LOG(@"invoke_method: Exception occurred!");
        return strdup("Exception occurred during invocation");
    }

    const Il2CppType* return_type = il2cpp_method_get_return_type(method);
    if (!return_type) {
        IL2CPP_LOG(@"invoke_method: No return type");
        return strdup("(void)");
    }

    int return_type_enum = il2cpp_type_get_type(return_type);
    IL2CPP_LOG(@"invoke_method: Return type enum: %d", return_type_enum);

    // format result
    char result_str[256];
    if (return_type_enum == IL2CPP_TYPE_VOID) {
        snprintf(result_str, sizeof(result_str), "(void)");
    }
    else if (!result) {
        snprintf(result_str, sizeof(result_str), "(null)");
    }
    else {
        switch (return_type_enum) {
            case IL2CPP_TYPE_BOOLEAN: {
                bool val = *(bool*)((char*)result + sizeof(Il2CppObject));
                snprintf(result_str, sizeof(result_str), "%s", val ? "true" : "false");
                break;
            }
            case IL2CPP_TYPE_I1: {
                int8_t val = *(int8_t*)((char*)result + sizeof(Il2CppObject));
                snprintf(result_str, sizeof(result_str), "%d", val);
                break;
            }
            case IL2CPP_TYPE_U1: {
                uint8_t val = *(uint8_t*)((char*)result + sizeof(Il2CppObject));
                snprintf(result_str, sizeof(result_str), "%u", val);
                break;
            }
            case IL2CPP_TYPE_I2: {
                int16_t val = *(int16_t*)((char*)result + sizeof(Il2CppObject));
                snprintf(result_str, sizeof(result_str), "%d", val);
                break;
            }
            case IL2CPP_TYPE_U2: {
                uint16_t val = *(uint16_t*)((char*)result + sizeof(Il2CppObject));
                snprintf(result_str, sizeof(result_str), "%u", val);
                break;
            }
            case IL2CPP_TYPE_I4: {
                int32_t val = *(int32_t*)((char*)result + sizeof(Il2CppObject));
                snprintf(result_str, sizeof(result_str), "%d", val);
                break;
            }
            case IL2CPP_TYPE_U4: {
                uint32_t val = *(uint32_t*)((char*)result + sizeof(Il2CppObject));
                snprintf(result_str, sizeof(result_str), "%u", val);
                break;
            }
            case IL2CPP_TYPE_I8: {
                int64_t val = *(int64_t*)((char*)result + sizeof(Il2CppObject));
                snprintf(result_str, sizeof(result_str), "%lld", val);
                break;
            }
            case IL2CPP_TYPE_U8: {
                uint64_t val = *(uint64_t*)((char*)result + sizeof(Il2CppObject));
                snprintf(result_str, sizeof(result_str), "%llu", val);
                break;
            }
            case IL2CPP_TYPE_R4: {
                float val = *(float*)((char*)result + sizeof(Il2CppObject));
                snprintf(result_str, sizeof(result_str), "%f", val);
                break;
            }
            case IL2CPP_TYPE_R8: {
                double val = *(double*)((char*)result + sizeof(Il2CppObject));
                snprintf(result_str, sizeof(result_str), "%f", val);
                break;
            }
            case IL2CPP_TYPE_STRING: {
                if (il2cpp_string_chars && result) {
                    const char* str = il2cpp_string_chars((Il2CppString*)result);
                    if (str) {
                        snprintf(result_str, sizeof(result_str), "\"%s\"", str);
                    } else {
                        snprintf(result_str, sizeof(result_str), "(null string)");
                    }
                } else {
                    snprintf(result_str, sizeof(result_str), "(string: %p)", result);
                }
                break;
            }
            default:
                snprintf(result_str, sizeof(result_str), "(object: %p)", result);
                break;
        }
    }

    IL2CPP_LOG(@"invoke_method: Result: %s", result_str);
    return strdup(result_str);
}

Il2CppFieldEnumResult* il2cpp_enumerate_fields(Il2CppClass* klass) {
    if (!klass || !il2cpp_class_get_fields) return NULL;

    // Count fields first
    int field_count = 0;
    void* iter = NULL;
    while (il2cpp_class_get_fields(klass, &iter)) {
        field_count++;
    }

    Il2CppFieldEnumResult* result = (Il2CppFieldEnumResult*)malloc(sizeof(Il2CppFieldEnumResult));
    result->fields = (Il2CppFieldInfo*)malloc(sizeof(Il2CppFieldInfo) * field_count);
    result->field_count = 0;

    // Enumerate fields
    iter = NULL;
    FieldInfo* field;
    while ((field = il2cpp_class_get_fields(klass, &iter))) {
        Il2CppFieldInfo* info = &result->fields[result->field_count];

        info->field = field;

        const char* name = il2cpp_field_get_name(field);
        info->name = strdup(name ? name : "<unknown>");

        const Il2CppType* field_type = il2cpp_field_get_type(field);
        const char* type_name = il2cpp_get_type_name(field_type);
        info->type_name = strdup(type_name);

        info->type_enum = il2cpp_type_get_type ? il2cpp_type_get_type(field_type) : 0;
        info->offset = il2cpp_field_get_offset ? il2cpp_field_get_offset(field) : 0;
        info->is_static = (info->offset == (size_t)-1);

        result->field_count++;
    }

    return result;
}

void il2cpp_free_field_enum_result(Il2CppFieldEnumResult* result) {
    if (!result) return;

    for (int i = 0; i < result->field_count; i++) {
        free(result->fields[i].name);
        free(result->fields[i].type_name);
    }

    free(result->fields);
    free(result);
}

char* il2cpp_get_field_value_string(void* obj, FieldInfo* field, Il2CppClass* klass) {
    if (!field) return strdup("(invalid field)");

    const Il2CppType* field_type = il2cpp_field_get_type(field);
    int type_enum = il2cpp_type_get_type ? il2cpp_type_get_type(field_type) : 0;

    char result_str[256];

    size_t offset = il2cpp_field_get_offset ? il2cpp_field_get_offset(field) : 0;
    bool is_static = (offset == (size_t)-1);

    union {
        bool bool_val;
        int8_t i1_val;
        uint8_t u1_val;
        int16_t i2_val;
        uint16_t u2_val;
        int32_t i4_val;
        uint32_t u4_val;
        int64_t i8_val;
        uint64_t u8_val;
        float f4_val;
        double f8_val;
        void* ptr_val;
    } value;

    if (is_static) {
        if (il2cpp_field_static_get_value && klass) {
            if (il2cpp_runtime_class_init) {
                il2cpp_runtime_class_init(klass);
            }
            il2cpp_field_static_get_value(field, &value);
        } else {
            return strdup("(cannot read static field)");
        }
    } else {
        if (il2cpp_field_get_value && obj) {
            il2cpp_field_get_value((Il2CppObject*)obj, field, &value);
        } else {
            return strdup("(no instance selected)");
        }
    }

    switch (type_enum) {
        case IL2CPP_TYPE_BOOLEAN:
            snprintf(result_str, sizeof(result_str), "%s", value.bool_val ? "true" : "false");
            break;
        case IL2CPP_TYPE_I1:
            snprintf(result_str, sizeof(result_str), "%d", value.i1_val);
            break;
        case IL2CPP_TYPE_U1:
            snprintf(result_str, sizeof(result_str), "%u", value.u1_val);
            break;
        case IL2CPP_TYPE_I2:
            snprintf(result_str, sizeof(result_str), "%d", value.i2_val);
            break;
        case IL2CPP_TYPE_U2:
            snprintf(result_str, sizeof(result_str), "%u", value.u2_val);
            break;
        case IL2CPP_TYPE_I4:
            snprintf(result_str, sizeof(result_str), "%d", value.i4_val);
            break;
        case IL2CPP_TYPE_U4:
            snprintf(result_str, sizeof(result_str), "%u", value.u4_val);
            break;
        case IL2CPP_TYPE_I8:
            snprintf(result_str, sizeof(result_str), "%lld", value.i8_val);
            break;
        case IL2CPP_TYPE_U8:
            snprintf(result_str, sizeof(result_str), "%llu", value.u8_val);
            break;
        case IL2CPP_TYPE_R4:
            snprintf(result_str, sizeof(result_str), "%f", value.f4_val);
            break;
        case IL2CPP_TYPE_R8:
            snprintf(result_str, sizeof(result_str), "%f", value.f8_val);
            break;
        case IL2CPP_TYPE_STRING:
            if (value.ptr_val && il2cpp_string_chars) {
                const char* str = il2cpp_string_chars((Il2CppString*)value.ptr_val);
                if (str) {
                    snprintf(result_str, sizeof(result_str), "\"%s\"", str);
                } else {
                    snprintf(result_str, sizeof(result_str), "(null string)");
                }
            } else {
                snprintf(result_str, sizeof(result_str), "(null)");
            }
            break;
        default:
            snprintf(result_str, sizeof(result_str), "(object: %p)", value.ptr_val);
            break;
    }

    return strdup(result_str);
}

bool il2cpp_set_field_value_from_string(void* obj, FieldInfo* field, Il2CppClass* klass, const char* value_str, int type_enum) {
    if (!field || !value_str) return false;

    size_t offset = il2cpp_field_get_offset ? il2cpp_field_get_offset(field) : 0;
    bool is_static = (offset == (size_t)-1);

    union {
        bool bool_val;
        int8_t i1_val;
        uint8_t u1_val;
        int16_t i2_val;
        uint16_t u2_val;
        int32_t i4_val;
        uint32_t u4_val;
        int64_t i8_val;
        uint64_t u8_val;
        float f4_val;
        double f8_val;
        void* ptr_val;
    } value;

    switch (type_enum) {
        case IL2CPP_TYPE_BOOLEAN:
            value.bool_val = (strcasecmp(value_str, "true") == 0) || (atoi(value_str) != 0);
            break;
        case IL2CPP_TYPE_I1:
            value.i1_val = (int8_t)atoi(value_str);
            break;
        case IL2CPP_TYPE_U1:
            value.u1_val = (uint8_t)atoi(value_str);
            break;
        case IL2CPP_TYPE_I2:
            value.i2_val = (int16_t)atoi(value_str);
            break;
        case IL2CPP_TYPE_U2:
            value.u2_val = (uint16_t)atoi(value_str);
            break;
        case IL2CPP_TYPE_I4:
            value.i4_val = (int32_t)atoi(value_str);
            break;
        case IL2CPP_TYPE_U4:
            value.u4_val = (uint32_t)strtoul(value_str, NULL, 10);
            break;
        case IL2CPP_TYPE_I8:
            value.i8_val = (int64_t)atoll(value_str);
            break;
        case IL2CPP_TYPE_U8:
            value.u8_val = (uint64_t)strtoull(value_str, NULL, 10);
            break;
        case IL2CPP_TYPE_R4:
            value.f4_val = (float)atof(value_str);
            break;
        case IL2CPP_TYPE_R8:
            value.f8_val = atof(value_str);
            break;
        case IL2CPP_TYPE_STRING:
            if (il2cpp_string_new) {
                value.ptr_val = il2cpp_string_new(value_str);
            } else {
                return false;
            }
            break;
        default:
            return false;
    }

    // Set the value
    if (is_static) {
        if (il2cpp_field_static_set_value && klass) {
            if (il2cpp_runtime_class_init) {
                il2cpp_runtime_class_init(klass);
            }
            il2cpp_field_static_set_value(field, &value);
            return true;
        }
    } else {
        if (il2cpp_field_set_value && obj) {
            il2cpp_field_set_value((Il2CppObject*)obj, field, &value);
            return true;
        }
    }

    return false;
}

bool il2cpp_can_edit_field_type(int type_enum) {
    switch (type_enum) {
        case IL2CPP_TYPE_BOOLEAN:
        case IL2CPP_TYPE_I1:
        case IL2CPP_TYPE_U1:
        case IL2CPP_TYPE_I2:
        case IL2CPP_TYPE_U2:
        case IL2CPP_TYPE_I4:
        case IL2CPP_TYPE_U4:
        case IL2CPP_TYPE_I8:
        case IL2CPP_TYPE_U8:
        case IL2CPP_TYPE_R4:
        case IL2CPP_TYPE_R8:
        case IL2CPP_TYPE_STRING:
            return true;
        default:
            return false;
    }
}

typedef struct {
    Il2CppObject** objects;
    int count;
    int capacity;
} InstanceCollector;

static void instance_callback(Il2CppObject** objects, int size, void* userdata) {
    InstanceCollector* collector = (InstanceCollector*)userdata;
    IL2CPP_LOG(@"instance_callback: Received %d objects", size);

    // Ensure capacity
    if (collector->count + size > collector->capacity) {
        int new_capacity = collector->capacity * 2;
        if (new_capacity < collector->count + size) {
            new_capacity = collector->count + size;
        }
        collector->objects = (Il2CppObject**)realloc(collector->objects, new_capacity * sizeof(Il2CppObject*));
        collector->capacity = new_capacity;
    }

    // Copy objects
    for (int i = 0; i < size; i++) {
        collector->objects[collector->count++] = objects[i];
    }
}

static void empty_world_callback(void) {
}

static void* realloc_callback(void* handle, size_t size, void* userdata) {
    if (handle && size == 0) {
        if (il2cpp_free) {
            il2cpp_free(handle);
        } else {
            free(handle);
        }
        return NULL;
    } else {
        if (il2cpp_alloc) {
            return il2cpp_alloc(size);
        } else {
            return malloc(size);
        }
    }
}

Il2CppInstanceEnumResult* il2cpp_find_instances(Il2CppClass* klass) {
    if (!klass) return NULL;

    IL2CPP_LOG(@"find_instances: Starting instance search for class");

    // confirm functions
    bool has_old_api = (il2cpp_unity_liveness_calculation_begin &&
                        il2cpp_unity_liveness_calculation_from_statics &&
                        il2cpp_unity_liveness_calculation_end);

    bool has_new_api = (il2cpp_unity_liveness_allocate_struct &&
                        il2cpp_unity_liveness_calculation_from_statics &&
                        il2cpp_unity_liveness_finalize &&
                        il2cpp_unity_liveness_free_struct &&
                        il2cpp_stop_gc_world &&
                        il2cpp_start_gc_world);

    if (!has_old_api && !has_new_api) {
        IL2CPP_LOG(@"find_instances: rerquired functions not found!");
        Il2CppInstanceEnumResult* result = (Il2CppInstanceEnumResult*)malloc(sizeof(Il2CppInstanceEnumResult));
        result->instances = NULL;
        result->instance_count = 0;
        return result;
    }

    InstanceCollector collector;
    collector.objects = (Il2CppObject**)malloc(sizeof(Il2CppObject*) * 100);
    collector.count = 0;
    collector.capacity = 100;

    void* state = NULL;

    @try {
        if (has_new_api) {
            IL2CPP_LOG(@"find_instances: Using new method");

            il2cpp_stop_gc_world();
            state = il2cpp_unity_liveness_allocate_struct(klass, 0, instance_callback, &collector, realloc_callback);
            if (state) {
                il2cpp_unity_liveness_calculation_from_statics(state);
                il2cpp_unity_liveness_finalize(state);
            }
            il2cpp_start_gc_world();
            if (state) {
                il2cpp_unity_liveness_free_struct(state);
            }
        } else {
            IL2CPP_LOG(@"find_instances: Using old method");
            state = il2cpp_unity_liveness_calculation_begin(klass, 0, instance_callback, &collector,
                                                             empty_world_callback, empty_world_callback);
            if (state) {
                il2cpp_unity_liveness_calculation_from_statics(state);
                il2cpp_unity_liveness_calculation_end(state);
            }
        }
    } @catch (NSException *exception) {
        IL2CPP_LOG(@"find_instances: Exception!: %@", exception);
        free(collector.objects);
        Il2CppInstanceEnumResult* result = (Il2CppInstanceEnumResult*)malloc(sizeof(Il2CppInstanceEnumResult));
        result->instances = NULL;
        result->instance_count = 0;
        return result;
    }

    IL2CPP_LOG(@"find_instances: Found %d instances", collector.count);

    // Build result
    Il2CppInstanceEnumResult* result = (Il2CppInstanceEnumResult*)malloc(sizeof(Il2CppInstanceEnumResult));

    if (collector.count > 0) {
        result->instances = (Il2CppInstanceInfo*)malloc(sizeof(Il2CppInstanceInfo) * collector.count);
        result->instance_count = collector.count;

        for (int i = 0; i < collector.count; i++) {
            result->instances[i].instance = collector.objects[i];
        }
    } else {
        result->instances = NULL;
        result->instance_count = 0;
    }

    free(collector.objects);
    return result;
}

void il2cpp_free_instance_enum_result(Il2CppInstanceEnumResult* result) {
    if (!result) return;
    if (result->instances) free(result->instances);
    free(result);
}
