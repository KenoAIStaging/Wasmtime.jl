# Store wrapper

"""
    Store

Represents a Wasmtime store which holds WebAssembly instances and their state.
"""
mutable struct Store
    ptr::WasmtimeStore
    context::WasmtimeContext
    engine::Engine  # Keep reference to prevent GC

    function Store(engine::Engine)
        store_ptr = ccall((:wasmtime_store_new, libwasmtime), WasmtimeStore,
                         (WasmEngine, Ptr{Cvoid}, Ptr{Cvoid}),
                         engine.ptr, C_NULL, C_NULL)

        if store_ptr == C_NULL
            error("Failed to create Wasmtime store")
        end

        # Get context pointer
        context_ptr = ccall((:wasmtime_store_context, libwasmtime), WasmtimeContext,
                           (WasmtimeStore,), store_ptr)

        store = new(store_ptr, context_ptr, engine)
        finalizer(store) do s
            ccall((:wasmtime_store_delete, libwasmtime), Cvoid, (WasmtimeStore,), s.ptr)
        end
        return store
    end
end

"""
    wasmtime_gc(store::Store)

Perform garbage collection in the store.
"""
function wasmtime_gc(store::Store)
    ccall((:wasmtime_context_gc, libwasmtime), Cvoid, (WasmtimeContext,), store.context)
end

"""
    set_fuel!(store::Store, fuel::Int64)

Set the fuel available for WebAssembly execution.
"""
function set_fuel!(store::Store, fuel::Int64)
    error_ptr = ccall((:wasmtime_context_set_fuel, libwasmtime), WasmtimeError,
                     (WasmtimeContext, UInt64), store.context, UInt64(fuel))
    check_error(error_ptr)
end

"""
    get_fuel(store::Store) -> Int64

Get the remaining fuel in the store.
"""
function get_fuel(store::Store)
    fuel = Ref{UInt64}(0)
    error_ptr = ccall((:wasmtime_context_get_fuel, libwasmtime), WasmtimeError,
                     (WasmtimeContext, Ptr{UInt64}), store.context, fuel)
    check_error(error_ptr)
    return Int64(fuel[])
end
