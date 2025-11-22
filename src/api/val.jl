# Value wrappers

"""
    Val

Abstract type for WebAssembly values.
"""
abstract type Val end

struct I32Val <: Val
    value::Int32
end

struct I64Val <: Val
    value::Int64
end

struct F32Val <: Val
    value::Float32
end

struct F64Val <: Val
    value::Float64
end

struct RefVal <: Val
    ptr::Ptr{Cvoid}
end

# Convert Julia values to WasmVal
function to_wasm_val(v::I32Val)
    return make_i32_val(v.value)
end

function to_wasm_val(v::I64Val)
    return make_i64_val(v.value)
end

function to_wasm_val(v::F32Val)
    return make_f32_val(v.value)
end

function to_wasm_val(v::F64Val)
    return make_f64_val(v.value)
end

# Convert WasmVal to Julia values
function from_wasm_val(v::WasmVal)
    if v.kind == WASM_I32
        return I32Val(get_i32(v))
    elseif v.kind == WASM_I64
        return I64Val(get_i64(v))
    elseif v.kind == WASM_F32
        return F32Val(get_f32(v))
    elseif v.kind == WASM_F64
        return F64Val(get_f64(v))
    else
        error("Unsupported value kind: $(v.kind)")
    end
end

# Convenience constructors
Val(x::Int32) = I32Val(x)
Val(x::Int64) = I64Val(x)
Val(x::Float32) = F32Val(x)
Val(x::Float64) = F64Val(x)
