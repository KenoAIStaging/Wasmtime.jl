# Engine wrapper

"""
    Engine

Represents a Wasmtime engine which holds compiled code and configuration.
Engines can be shared across multiple stores.
"""
mutable struct Engine
    ptr::WasmEngine

    function Engine(ptr::WasmEngine)
        engine = new(ptr)
        finalizer(engine) do e
            ccall((:wasm_engine_delete, libwasmtime), Cvoid, (WasmEngine,), e.ptr)
        end
        return engine
    end
end

"""
    Engine(; gc=true, reference_types=true, multi_memory=true, simd=true, function_references=true)

Create a new engine with custom configuration.
Note: GC requires function_references to be enabled.
Requires Wasmtime v27.0.0+ for full GC support.
"""
function Engine(; gc::Bool=true, reference_types::Bool=true,
                multi_memory::Bool=true, simd::Bool=true, function_references::Bool=true)
    config_ptr = ccall((:wasm_config_new, libwasmtime), WasmConfig, ())

    # GC requires function_references, so enable it if gc is enabled
    if gc || function_references
        ccall((:wasmtime_config_wasm_function_references_set, libwasmtime), Cvoid,
              (WasmConfig, Bool), config_ptr, true)
    end

    if gc
        ccall((:wasmtime_config_wasm_gc_set, libwasmtime), Cvoid,
              (WasmConfig, Bool), config_ptr, true)
    end

    if reference_types
        ccall((:wasmtime_config_wasm_reference_types_set, libwasmtime), Cvoid,
              (WasmConfig, Bool), config_ptr, true)
    end

    if multi_memory
        ccall((:wasmtime_config_wasm_multi_memory_set, libwasmtime), Cvoid,
              (WasmConfig, Bool), config_ptr, true)
    end

    if simd
        ccall((:wasmtime_config_wasm_simd_set, libwasmtime), Cvoid,
              (WasmConfig, Bool), config_ptr, true)
    end

    engine_ptr = ccall((:wasm_engine_new_with_config, libwasmtime), WasmEngine,
                      (WasmConfig,), config_ptr)

    if engine_ptr == C_NULL
        error("Failed to create Wasmtime engine")
    end

    return Engine(engine_ptr)
end
