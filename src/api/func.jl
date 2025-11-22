# Function wrapper

"""
    Func

Represents a WebAssembly function.
"""
struct Func
    store::Store
    ptr::WasmtimeFunc
end

"""
    call(func::Func, args::Vector{Val}) -> Vector{Val}

Call a WebAssembly function with the given arguments.
"""
function call(func::Func, args::Vector{<:Val})
    # Convert Julia values to WASM values
    wasm_args = [to_wasm_val(arg) for arg in args]

    # Prepare results array (assume max 1 result for now)
    wasm_results = Vector{WasmVal}(undef, 1)

    # Call function
    trap_ptr = Ref{Ptr{Cvoid}}(C_NULL)
    error_ptr = ccall((:wasmtime_func_call, libwasmtime), WasmtimeError,
                     (WasmtimeContext, Ref{WasmtimeFunc}, Ptr{WasmVal}, Csize_t,
                      Ptr{WasmVal}, Csize_t, Ptr{Ptr{Cvoid}}),
                     func.store.context, Ref(func.ptr), wasm_args, length(wasm_args),
                     wasm_results, length(wasm_results), trap_ptr)

    check_error(error_ptr)

    if trap_ptr[] != C_NULL
        ccall((:wasm_trap_delete, libwasmtime), Cvoid, (Ptr{Cvoid},), trap_ptr[])
        error("Trap occurred during function call")
    end

    # Convert results back to Julia
    results = Val[]
    if length(wasm_results) > 0 && wasm_results[1].kind != WASM_I32  # Check if valid
        push!(results, from_wasm_val(wasm_results[1]))
    end

    return results
end

"""
    call(func::Func, args...) -> Val

Convenience method to call a function with individual arguments.
"""
function call(func::Func, args...)
    julia_args = [Val(arg) for arg in args]
    results = call(func, julia_args)
    return length(results) > 0 ? results[1] : nothing
end
