# Instance wrapper

# Wasmtime extern type (matches C struct)
struct WasmtimeExternUnion
    func::WasmtimeFunc
end

struct WasmtimeExtern
    kind::WasmtimeExternKind
    of::WasmtimeExternUnion
end

"""
    Instance

Represents an instantiated WebAssembly module.
"""
mutable struct Instance
    wasm_module::Module
    store::Store
    ptr::WasmtimeInstance
    exports::Dict{String, WasmtimeExtern}

    function Instance(store::Store, mod::Module, imports::Vector=[])
        # Create instance
        instance = Ref{WasmtimeInstance}()
        trap_ptr = Ref{Ptr{Cvoid}}(C_NULL)

        # Empty imports vector
        imports_array = WasmtimeExtern[]

        error_ptr = ccall((:wasmtime_instance_new, libwasmtime), WasmtimeError,
                         (WasmtimeContext, WasmtimeModule, Ptr{WasmtimeExtern},
                          Csize_t, Ptr{WasmtimeInstance}, Ptr{Ptr{Cvoid}}),
                         store.context, mod.ptr, imports_array,
                         length(imports_array), instance, trap_ptr)

        check_error(error_ptr)

        if trap_ptr[] != C_NULL
            ccall((:wasm_trap_delete, libwasmtime), Cvoid, (Ptr{Cvoid},), trap_ptr[])
            error("Trap occurred during instantiation")
        end

        # Get exports by iterating through module exports
        exports_dict = Dict{String, WasmtimeExtern}()

        inst = new(mod, store, instance[], exports_dict)
        return inst
    end
end

"""
    instantiate(store::Store, module::Module) -> Instance

Instantiate a WebAssembly module in the given store.
"""
function instantiate(store::Store, mod::Module)
    return Instance(store, mod)
end

"""
    get_export(instance::Instance, name::String) -> WasmtimeExtern

Get an exported item from the instance by name.
"""
function get_export(instance::Instance, name::String)
    # Use wasmtime_instance_export_nth to iterate through exports
    # This is more reliable than export_get with name lookups

    idx = 0
    while true
        name_vec = Ref{ByteVec}()
        item = Ref{WasmtimeExtern}()

        found = ccall((:wasmtime_instance_export_nth, libwasmtime), Bool,
                     (WasmtimeContext, Ref{WasmtimeInstance}, Csize_t,
                      Ptr{ByteVec}, Ptr{WasmtimeExtern}),
                     instance.store.context, Ref(instance.ptr), idx, name_vec, item)

        if !found
            break  # No more exports
        end

        # Check if this is the export we're looking for
        export_name_bytes = to_julia_array(name_vec[])
        export_name = String(copy(export_name_bytes))

        if export_name == name
            return item[]
        end

        idx += 1
    end

    error("Export '$name' not found")
end

"""
    get_func(instance::Instance, name::String) -> Func

Get an exported function from the instance.
"""
function get_func(instance::Instance, name::String)
    item = get_export(instance, name)
    if item.kind != WASMTIME_EXTERN_FUNC
        error("Export '$name' is not a function")
    end
    return Func(instance.store, item.of.func)
end
