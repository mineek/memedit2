#ifndef il2cpp_api_h
#define il2cpp_api_h

#include "il2cpp_types.h"

typedef Il2CppDomain* (*il2cpp_domain_get_t)(void);
typedef const Il2CppAssembly** (*il2cpp_domain_get_assemblies_t)(const Il2CppDomain* domain, size_t* size);

typedef const Il2CppImage* (*il2cpp_assembly_get_image_t)(const Il2CppAssembly* assembly);

typedef const char* (*il2cpp_image_get_name_t)(const Il2CppImage* image);
typedef size_t (*il2cpp_image_get_class_count_t)(const Il2CppImage* image);
typedef const Il2CppClass* (*il2cpp_image_get_class_t)(const Il2CppImage* image, size_t index);

typedef const char* (*il2cpp_class_get_name_t)(Il2CppClass* klass);
typedef const char* (*il2cpp_class_get_namespace_t)(Il2CppClass* klass);
typedef const MethodInfo* (*il2cpp_class_get_methods_t)(Il2CppClass* klass, void** iter);
typedef FieldInfo* (*il2cpp_class_get_fields_t)(Il2CppClass* klass, void** iter);

typedef const char* (*il2cpp_method_get_name_t)(const MethodInfo* method);
typedef const Il2CppType* (*il2cpp_method_get_return_type_t)(const MethodInfo* method);
typedef uint32_t (*il2cpp_method_get_param_count_t)(const MethodInfo* method);
typedef const Il2CppType* (*il2cpp_method_get_param_t)(const MethodInfo* method, uint32_t index);
typedef const char* (*il2cpp_method_get_param_name_t)(const MethodInfo* method, uint32_t index);
typedef uint32_t (*il2cpp_method_get_flags_t)(const MethodInfo* method, uint32_t* iflags);
typedef bool (*il2cpp_method_is_instance_t)(const MethodInfo* method);

typedef int (*il2cpp_type_get_type_t)(const Il2CppType* type);
typedef char* (*il2cpp_type_get_name_t)(const Il2CppType* type);
typedef bool (*il2cpp_type_is_byref_t)(const Il2CppType* type);

typedef const char* (*il2cpp_field_get_name_t)(FieldInfo* field);
typedef const Il2CppType* (*il2cpp_field_get_type_t)(FieldInfo* field);
typedef size_t (*il2cpp_field_get_offset_t)(FieldInfo* field);
typedef FieldInfo* (*il2cpp_class_get_field_from_name_t)(Il2CppClass* klass, const char* name);
typedef void (*il2cpp_field_static_get_value_t)(FieldInfo* field, void* value);
typedef void (*il2cpp_field_get_value_t)(Il2CppObject* obj, FieldInfo* field, void* value);
typedef void (*il2cpp_runtime_class_init_t)(Il2CppClass* klass);

// runtime funcs
typedef Il2CppObject* (*il2cpp_runtime_invoke_t)(const MethodInfo* method, void* obj, void** params, Il2CppObject** exc);
typedef Il2CppObject* (*il2cpp_object_new_t)(Il2CppClass* klass);
typedef Il2CppString* (*il2cpp_string_new_t)(const char* str);
typedef const char* (*il2cpp_string_chars_t)(Il2CppString* str);
typedef Il2CppObject* (*il2cpp_value_box_t)(Il2CppClass* klass, void* data);

// globals
extern il2cpp_domain_get_t il2cpp_domain_get;
extern il2cpp_domain_get_assemblies_t il2cpp_domain_get_assemblies;

extern il2cpp_assembly_get_image_t il2cpp_assembly_get_image;

extern il2cpp_image_get_name_t il2cpp_image_get_name;
extern il2cpp_image_get_class_count_t il2cpp_image_get_class_count;
extern il2cpp_image_get_class_t il2cpp_image_get_class;

extern il2cpp_class_get_name_t il2cpp_class_get_name;
extern il2cpp_class_get_namespace_t il2cpp_class_get_namespace;
extern il2cpp_class_get_methods_t il2cpp_class_get_methods;
extern il2cpp_class_get_fields_t il2cpp_class_get_fields;

extern il2cpp_method_get_name_t il2cpp_method_get_name;
extern il2cpp_method_get_return_type_t il2cpp_method_get_return_type;
extern il2cpp_method_get_param_count_t il2cpp_method_get_param_count;
extern il2cpp_method_get_param_t il2cpp_method_get_param;
extern il2cpp_method_get_param_name_t il2cpp_method_get_param_name;
extern il2cpp_method_get_flags_t il2cpp_method_get_flags;
extern il2cpp_method_is_instance_t il2cpp_method_is_instance;

extern il2cpp_type_get_type_t il2cpp_type_get_type;
extern il2cpp_type_get_name_t il2cpp_type_get_name;
extern il2cpp_type_is_byref_t il2cpp_type_is_byref;

extern il2cpp_field_get_name_t il2cpp_field_get_name;
extern il2cpp_field_get_type_t il2cpp_field_get_type;
extern il2cpp_field_get_offset_t il2cpp_field_get_offset;
extern il2cpp_class_get_field_from_name_t il2cpp_class_get_field_from_name;
extern il2cpp_field_static_get_value_t il2cpp_field_static_get_value;
extern il2cpp_field_get_value_t il2cpp_field_get_value;
extern il2cpp_runtime_class_init_t il2cpp_runtime_class_init;

extern il2cpp_runtime_invoke_t il2cpp_runtime_invoke;
extern il2cpp_object_new_t il2cpp_object_new;
extern il2cpp_string_new_t il2cpp_string_new;
extern il2cpp_string_chars_t il2cpp_string_chars;
extern il2cpp_value_box_t il2cpp_value_box;

typedef void (*il2cpp_field_static_set_value_t)(FieldInfo* field, void* value);
typedef void (*il2cpp_field_set_value_t)(Il2CppObject* obj, FieldInfo* field, void* value);

extern il2cpp_field_static_set_value_t il2cpp_field_static_set_value;
extern il2cpp_field_set_value_t il2cpp_field_set_value;

typedef void (*il2cpp_liveness_callback_t)(Il2CppObject** objects, int size, void* userdata);
typedef void (*il2cpp_world_callback_t)(void);
typedef void* (*il2cpp_realloc_callback_t)(void* handle, size_t size, void* userdata);

// Unity < 2021.2.0
typedef void* (*il2cpp_unity_liveness_calculation_begin_t)(Il2CppClass* klass, int max_count, il2cpp_liveness_callback_t callback, void* userdata, il2cpp_world_callback_t onStartWorld, il2cpp_world_callback_t onStopWorld);
typedef void (*il2cpp_unity_liveness_calculation_from_statics_t)(void* state);
typedef void (*il2cpp_unity_liveness_calculation_end_t)(void* state);

// Unity >= 2021.2.0
typedef void* (*il2cpp_unity_liveness_allocate_struct_t)(Il2CppClass* klass, int max_count, il2cpp_liveness_callback_t callback, void* userdata, il2cpp_realloc_callback_t reallocCallback);
typedef void (*il2cpp_unity_liveness_finalize_t)(void* state);
typedef void (*il2cpp_unity_liveness_free_struct_t)(void* state);
typedef void (*il2cpp_stop_gc_world_t)(void);
typedef void (*il2cpp_start_gc_world_t)(void);

extern il2cpp_unity_liveness_calculation_begin_t il2cpp_unity_liveness_calculation_begin;
extern il2cpp_unity_liveness_calculation_from_statics_t il2cpp_unity_liveness_calculation_from_statics;
extern il2cpp_unity_liveness_calculation_end_t il2cpp_unity_liveness_calculation_end;
extern il2cpp_unity_liveness_allocate_struct_t il2cpp_unity_liveness_allocate_struct;
extern il2cpp_unity_liveness_finalize_t il2cpp_unity_liveness_finalize;
extern il2cpp_unity_liveness_free_struct_t il2cpp_unity_liveness_free_struct;
extern il2cpp_stop_gc_world_t il2cpp_stop_gc_world;
extern il2cpp_start_gc_world_t il2cpp_start_gc_world;

typedef void* (*il2cpp_alloc_t)(size_t size);
typedef void (*il2cpp_free_t)(void* ptr);

extern il2cpp_alloc_t il2cpp_alloc;
extern il2cpp_free_t il2cpp_free;

bool il2cpp_api_init(void);
bool il2cpp_api_is_available(void);

#endif /* il2cpp_api_h */
