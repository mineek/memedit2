#include "il2cpp_api.h"
#include <dlfcn.h>
#include <stdio.h>
#include <stdbool.h>
#include <mach-o/dyld.h>
#include <string.h>

#import <Foundation/Foundation.h>
#import "../RemoteLog.h"
#define IL2CPP_LOG(...) RLog(__VA_ARGS__)

il2cpp_domain_get_t il2cpp_domain_get = NULL;
il2cpp_domain_get_assemblies_t il2cpp_domain_get_assemblies = NULL;

il2cpp_assembly_get_image_t il2cpp_assembly_get_image = NULL;

il2cpp_image_get_name_t il2cpp_image_get_name = NULL;
il2cpp_image_get_class_count_t il2cpp_image_get_class_count = NULL;
il2cpp_image_get_class_t il2cpp_image_get_class = NULL;

il2cpp_class_get_name_t il2cpp_class_get_name = NULL;
il2cpp_class_get_namespace_t il2cpp_class_get_namespace = NULL;
il2cpp_class_get_methods_t il2cpp_class_get_methods = NULL;
il2cpp_class_get_fields_t il2cpp_class_get_fields = NULL;

il2cpp_method_get_name_t il2cpp_method_get_name = NULL;
il2cpp_method_get_return_type_t il2cpp_method_get_return_type = NULL;
il2cpp_method_get_param_count_t il2cpp_method_get_param_count = NULL;
il2cpp_method_get_param_t il2cpp_method_get_param = NULL;
il2cpp_method_get_param_name_t il2cpp_method_get_param_name = NULL;
il2cpp_method_get_flags_t il2cpp_method_get_flags = NULL;
il2cpp_method_is_instance_t il2cpp_method_is_instance = NULL;

il2cpp_type_get_type_t il2cpp_type_get_type = NULL;
il2cpp_type_get_name_t il2cpp_type_get_name = NULL;
il2cpp_type_is_byref_t il2cpp_type_is_byref = NULL;

il2cpp_field_get_name_t il2cpp_field_get_name = NULL;
il2cpp_field_get_type_t il2cpp_field_get_type = NULL;
il2cpp_field_get_offset_t il2cpp_field_get_offset = NULL;
il2cpp_class_get_field_from_name_t il2cpp_class_get_field_from_name = NULL;
il2cpp_field_static_get_value_t il2cpp_field_static_get_value = NULL;
il2cpp_field_get_value_t il2cpp_field_get_value = NULL;
il2cpp_runtime_class_init_t il2cpp_runtime_class_init = NULL;

il2cpp_runtime_invoke_t il2cpp_runtime_invoke = NULL;
il2cpp_object_new_t il2cpp_object_new = NULL;
il2cpp_string_new_t il2cpp_string_new = NULL;
il2cpp_string_chars_t il2cpp_string_chars = NULL;
il2cpp_value_box_t il2cpp_value_box = NULL;

il2cpp_field_static_set_value_t il2cpp_field_static_set_value = NULL;
il2cpp_field_set_value_t il2cpp_field_set_value = NULL;

il2cpp_unity_liveness_calculation_begin_t il2cpp_unity_liveness_calculation_begin = NULL;
il2cpp_unity_liveness_calculation_from_statics_t il2cpp_unity_liveness_calculation_from_statics = NULL;
il2cpp_unity_liveness_calculation_end_t il2cpp_unity_liveness_calculation_end = NULL;
il2cpp_unity_liveness_allocate_struct_t il2cpp_unity_liveness_allocate_struct = NULL;
il2cpp_unity_liveness_finalize_t il2cpp_unity_liveness_finalize = NULL;
il2cpp_unity_liveness_free_struct_t il2cpp_unity_liveness_free_struct = NULL;
il2cpp_stop_gc_world_t il2cpp_stop_gc_world = NULL;
il2cpp_start_gc_world_t il2cpp_start_gc_world = NULL;

il2cpp_alloc_t il2cpp_alloc = NULL;
il2cpp_free_t il2cpp_free = NULL;

static bool api_initialized = false;
static void* il2cpp_handle = NULL;

#define RESOLVE_FUNC(name) \
    name = (name##_t)dlsym(il2cpp_handle, #name); \
    if (!name) { \
        IL2CPP_LOG(@"Failed to get function %s: %s", #name, dlerror()); \
    } else { \
        IL2CPP_LOG(@"%s @ %p", #name, name); \
    }

bool il2cpp_api_init(void) {
    IL2CPP_LOG(@"Init il2cpp!");

    if (api_initialized) {
        IL2CPP_LOG(@"il2cpp already inited!");
        return true;
    }

    // is this even a unity il2cpp game?
    IL2CPP_LOG(@"Verifying if this is a unity il2cpp game");
    uint32_t image_count = _dyld_image_count();
    bool found_unity = false;

    for (uint32_t i = 0; i < image_count; i++) {
        const char* image_name = _dyld_get_image_name(i);
        if (image_name) {
            if (strstr(image_name, "UnityFramework") ||
                strstr(image_name, "libil2cpp") ||
                strstr(image_name, "libunity")) {
                IL2CPP_LOG(@"Yes, found Unity library: %s", image_name);
                found_unity = true;
                break;
            }
        }
    }

    if (!found_unity) {
        IL2CPP_LOG(@"This may not be a unity game");
        return false;
    }

    // load unityframework dylib so we can resolve symbols
    const char* unity_framework_path = NULL;
    for (uint32_t i = 0; i < image_count; i++) {
        const char* image_name = _dyld_get_image_name(i);
        if (image_name && strstr(image_name, "UnityFramework")) {
            unity_framework_path = image_name;
            break;
        }
    }

    if (unity_framework_path) {
        IL2CPP_LOG(@"Trying to load UnityFramework with path %s", unity_framework_path);
        il2cpp_handle = dlopen(unity_framework_path, RTLD_LAZY | RTLD_NOLOAD);
        if (il2cpp_handle) {
            IL2CPP_LOG(@"success!");
        } else {
            il2cpp_handle = dlopen(unity_framework_path, RTLD_LAZY);
            if (il2cpp_handle) {
                IL2CPP_LOG(@"success on second try!");
            } else {
                IL2CPP_LOG(@"failed to load UnityFramework: %s", dlerror());
            }
        }
    }

    // fallback
    if (!il2cpp_handle) {
        const char* lib_names[] = {
            "UnityFramework",
            "libil2cpp.so",
            "GameAssembly.dll",
            NULL
        };

        for (int i = 0; lib_names[i] != NULL; i++) {
            il2cpp_handle = dlopen(lib_names[i], RTLD_LAZY);
            if (il2cpp_handle) {
                IL2CPP_LOG(@"success on %s", lib_names[i]);
                break;
            } else {
                IL2CPP_LOG(@"Failed to load %s: %s", lib_names[i], dlerror());
            }
        }
    }

    if (!il2cpp_handle) {
        IL2CPP_LOG(@"Didn't find explicit il2cpp handle");
        il2cpp_handle = RTLD_DEFAULT;
    }

    // resolve functions
    IL2CPP_LOG(@"Getting Unity functions!");
    RESOLVE_FUNC(il2cpp_domain_get);
    RESOLVE_FUNC(il2cpp_domain_get_assemblies);

    RESOLVE_FUNC(il2cpp_assembly_get_image);

    RESOLVE_FUNC(il2cpp_image_get_name);
    RESOLVE_FUNC(il2cpp_image_get_class_count);
    RESOLVE_FUNC(il2cpp_image_get_class);

    RESOLVE_FUNC(il2cpp_class_get_name);
    RESOLVE_FUNC(il2cpp_class_get_namespace);
    RESOLVE_FUNC(il2cpp_class_get_methods);
    RESOLVE_FUNC(il2cpp_class_get_fields);

    RESOLVE_FUNC(il2cpp_method_get_name);
    RESOLVE_FUNC(il2cpp_method_get_return_type);
    RESOLVE_FUNC(il2cpp_method_get_param_count);
    RESOLVE_FUNC(il2cpp_method_get_param);
    RESOLVE_FUNC(il2cpp_method_get_param_name);
    RESOLVE_FUNC(il2cpp_method_get_flags);
    RESOLVE_FUNC(il2cpp_method_is_instance);

    RESOLVE_FUNC(il2cpp_type_get_type);
    RESOLVE_FUNC(il2cpp_type_get_name);
    RESOLVE_FUNC(il2cpp_type_is_byref);

    RESOLVE_FUNC(il2cpp_field_get_name);
    RESOLVE_FUNC(il2cpp_field_get_type);
    RESOLVE_FUNC(il2cpp_field_get_offset);
    RESOLVE_FUNC(il2cpp_class_get_field_from_name);
    RESOLVE_FUNC(il2cpp_field_static_get_value);
    RESOLVE_FUNC(il2cpp_field_get_value);
    RESOLVE_FUNC(il2cpp_runtime_class_init);

    RESOLVE_FUNC(il2cpp_runtime_invoke);
    RESOLVE_FUNC(il2cpp_object_new);
    RESOLVE_FUNC(il2cpp_string_new);
    RESOLVE_FUNC(il2cpp_string_chars);
    RESOLVE_FUNC(il2cpp_value_box);

    RESOLVE_FUNC(il2cpp_field_static_set_value);
    RESOLVE_FUNC(il2cpp_field_set_value);

    RESOLVE_FUNC(il2cpp_unity_liveness_calculation_begin);
    RESOLVE_FUNC(il2cpp_unity_liveness_calculation_from_statics);
    RESOLVE_FUNC(il2cpp_unity_liveness_calculation_end);
    RESOLVE_FUNC(il2cpp_unity_liveness_allocate_struct);
    RESOLVE_FUNC(il2cpp_unity_liveness_finalize);
    RESOLVE_FUNC(il2cpp_unity_liveness_free_struct);
    RESOLVE_FUNC(il2cpp_stop_gc_world);
    RESOLVE_FUNC(il2cpp_start_gc_world);

    RESOLVE_FUNC(il2cpp_alloc);
    RESOLVE_FUNC(il2cpp_free);

    // verify minimum required functions are resolved
    IL2CPP_LOG(@"Checking minimum required functions...");
    IL2CPP_LOG(@"  il2cpp_domain_get: %p", il2cpp_domain_get);
    IL2CPP_LOG(@"  il2cpp_domain_get_assemblies: %p", il2cpp_domain_get_assemblies);
    IL2CPP_LOG(@"  il2cpp_assembly_get_image: %p", il2cpp_assembly_get_image);
    IL2CPP_LOG(@"  il2cpp_image_get_name: %p", il2cpp_image_get_name);

    if (il2cpp_domain_get && il2cpp_domain_get_assemblies &&
        il2cpp_assembly_get_image && il2cpp_image_get_name) {
        api_initialized = true;
        IL2CPP_LOG(@"il2cpp api initialized successfully!");
        return true;
    }

    IL2CPP_LOG(@"Failed to initialize il2cpp api ( did not found all required symbols )");
    return false;
}

bool il2cpp_api_is_available(void) {
    return api_initialized;
}
