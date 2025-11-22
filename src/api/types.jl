# Low-level type wrappers for Wasmtime C API

const libwasmtime = Wasmtime_jll.libwasmtime

# Opaque pointer types matching C API
const WasmConfig = Ptr{Cvoid}
const WasmEngine = Ptr{Cvoid}
const WasmtimeStore = Ptr{Cvoid}
const WasmtimeContext = Ptr{Cvoid}
const WasmtimeModule = Ptr{Cvoid}
const WasmtimeInstance = Ptr{Cvoid}
const WasmtimeFunc = Ptr{Cvoid}
const WasmtimeMemory = Ptr{Cvoid}
const WasmtimeGlobal = Ptr{Cvoid}
const WasmtimeTable = Ptr{Cvoid}
const WasmtimeError = Ptr{Cvoid}

# Byte vector type (used for byte arrays)
struct ByteVec
    size::Csize_t
    data::Ptr{UInt8}
end

# Utility function to create a byte vector from Julia bytes
function make_byte_vec(bytes::Vector{UInt8})
    data_ptr = pointer(bytes)
    return ByteVec(length(bytes), data_ptr)
end

# Utility function to convert ByteVec to Julia array
function to_julia_array(vec::ByteVec)
    if vec.data == C_NULL
        return UInt8[]
    end
    return unsafe_wrap(Array, vec.data, vec.size; own=false)
end

# Free a byte vector
function free_byte_vec!(vec::Ref{ByteVec})
    ccall((:wasm_byte_vec_delete, libwasmtime), Cvoid, (Ptr{ByteVec},), vec)
end

# Value kind enum (matching C API)
@enum WasmValKind::UInt8 begin
    WASM_I32 = 0
    WASM_I64 = 1
    WASM_F32 = 2
    WASM_F64 = 3
    WASM_EXTERNREF = 128
    WASM_FUNCREF = 129
end

# Value union (matching C API)
struct WasmValUnion
    i64::Int64  # Largest type, others alias this
end

# Value type
struct WasmVal
    kind::WasmValKind
    of::WasmValUnion
end

# Helper constructors for WasmVal
function make_i32_val(val::Int32)
    WasmVal(WASM_I32, WasmValUnion(Int64(val)))
end

function make_i64_val(val::Int64)
    WasmVal(WASM_I64, WasmValUnion(val))
end

function make_f32_val(val::Float32)
    bits = reinterpret(Int32, val)
    WasmVal(WASM_F32, WasmValUnion(Int64(bits)))
end

function make_f64_val(val::Float64)
    bits = reinterpret(Int64, val)
    WasmVal(WASM_F64, WasmValUnion(bits))
end

# Extract value from WasmVal
function get_i32(val::WasmVal)
    @assert val.kind == WASM_I32
    return Int32(val.of.i64)
end

function get_i64(val::WasmVal)
    @assert val.kind == WASM_I64
    return val.of.i64
end

function get_f32(val::WasmVal)
    @assert val.kind == WASM_F32
    bits = Int32(val.of.i64)
    return reinterpret(Float32, bits)
end

function get_f64(val::WasmVal)
    @assert val.kind == WASM_F64
    return reinterpret(Float64, val.of.i64)
end

# Wasmtime-specific error handling
struct WasmtimeErrorInfo
    message::String
end

function get_error_message(error_ptr::WasmtimeError)
    if error_ptr == C_NULL
        return nothing
    end

    # Get error message
    msg_vec = Ref{ByteVec}()
    ccall((:wasmtime_error_message, libwasmtime), Cvoid,
          (WasmtimeError, Ptr{ByteVec}), error_ptr, msg_vec)

    msg_bytes = to_julia_array(msg_vec[])
    message = String(copy(msg_bytes))

    free_byte_vec!(msg_vec)
    ccall((:wasmtime_error_delete, libwasmtime), Cvoid, (WasmtimeError,), error_ptr)

    return WasmtimeErrorInfo(message)
end

# Exception for Wasmtime errors
struct WasmtimeException <: Exception
    info::WasmtimeErrorInfo
end

Base.showerror(io::IO, e::WasmtimeException) = print(io, "WasmtimeException: ", e.info.message)

# Check error and throw if present
function check_error(error_ptr::WasmtimeError)
    if error_ptr != C_NULL
        err_info = get_error_message(error_ptr)
        throw(WasmtimeException(err_info))
    end
end
