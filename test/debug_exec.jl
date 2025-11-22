using Wasmtime
import Pkg
Pkg.develop(path="/workspace/WasmCore")
using WasmCore

println("Building simple module...")
builder = ModuleBuilder()
func_type = FuncType([I32, I32], [I32])
func_body = [
    local_get(UInt32(0)),
    local_get(UInt32(1)),
    i32_add()
]
func_idx = func(builder, func_type, Tuple{UInt32, ValType}[], func_body)
export_func(builder, "add", UInt32(func_idx))

wasm_module = build(builder)
bytes = encode_module(wasm_module)

println("Creating engine and store...")
engine = Engine()
store = Store(engine)

println("Compiling module...")
rt_module = compile(engine, bytes)

println("Instantiating...")
try
    instance = instantiate(store, rt_module)
    println("✓ Instance created successfully!")
    println("Instance ptr: ", instance.ptr)
    println("Store context: ", instance.store.context)

    println("\nTrying to get export...")
    item = get_export(instance, "add")
    println("✓ Got export!")
catch e
    println("✗ Error: $e")
    rethrow(e)
end
