# Module wrapper

"""
    Module

Represents a compiled WebAssembly module.
"""
mutable struct Module
    ptr::WasmtimeModule
    engine::Engine  # Keep reference to prevent GC

    function Module(engine::Engine, bytes::Vector{UInt8})
        module_ref = Ref{WasmtimeModule}(C_NULL)

        error_ptr = ccall((:wasmtime_module_new, libwasmtime), WasmtimeError,
                         (WasmEngine, Ptr{UInt8}, Csize_t, Ptr{WasmtimeModule}),
                         engine.ptr, bytes, length(bytes), module_ref)

        check_error(error_ptr)

        if module_ref[] == C_NULL
            error("Failed to create module")
        end

        mod = new(module_ref[], engine)
        finalizer(mod) do m
            ccall((:wasmtime_module_delete, libwasmtime), Cvoid,
                 (WasmtimeModule,), m.ptr)
        end
        return mod
    end
end

"""
    Module(engine::Engine, filename::String)

Load and compile a WebAssembly module from a file.
"""
function Module(engine::Engine, filename::String)
    bytes = read(filename)
    return Module(engine, bytes)
end

"""
    compile(engine::Engine, bytes::Vector{UInt8}) -> Module

Compile WebAssembly bytes into a module.
"""
function compile(engine::Engine, bytes::Vector{UInt8})
    return Module(engine, bytes)
end

"""
    validate(engine::Engine, bytes::Vector{UInt8}) -> Bool

Validate WebAssembly bytes without compiling.
"""
function validate(engine::Engine, bytes::Vector{UInt8})
    error_ptr = ccall((:wasmtime_module_validate, libwasmtime), WasmtimeError,
                     (WasmEngine, Ptr{UInt8}, Csize_t),
                     engine.ptr, bytes, length(bytes))

    if error_ptr == C_NULL
        return true
    else
        # Free the error without throwing
        ccall((:wasmtime_error_delete, libwasmtime), Cvoid,
             (WasmtimeError,), error_ptr)
        return false
    end
end
