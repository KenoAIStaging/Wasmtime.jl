module Wasmtime

using Wasmtime_jll

# Core API wrappers
include("api/types.jl")
include("api/engine.jl")
include("api/store.jl")
include("api/module.jl")
include("api/instance.jl")
include("api/func.jl")
include("api/memory.jl")
include("api/val.jl")

# Re-export main functionality
export Engine, Store, Module, Instance
export Func, Memory, Global, Table
export Val, I32Val, I64Val, F32Val, F64Val, RefVal
export call, get_memory, read_memory, write_memory
export compile, validate, instantiate
export get_export, wasmtime_gc, set_fuel!, get_fuel

end # module Wasmtime
