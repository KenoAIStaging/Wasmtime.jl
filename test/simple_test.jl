using Wasmtime

import Pkg
Pkg.develop(path="/workspace/WasmCore")
using WasmCore

println("Testing Engine creation...")
engine = Engine()
println("✓ Engine created")

println("\nTesting Store creation...")
store = Store(engine)
println("✓ Store created")

println("\nTesting simple WASM module validation...")
# Minimal valid WASM module (just magic + version)
minimal_wasm = UInt8[
    0x00, 0x61, 0x73, 0x6d,  # Magic
    0x01, 0x00, 0x00, 0x00,  # Version
]
result = validate(engine, minimal_wasm)
println("✓ Minimal module validation: $result")

println("\nTesting WasmCore ModuleBuilder...")
builder = ModuleBuilder()
println("✓ ModuleBuilder created")

println("\nBuilding simple add function...")
func_type = FuncType([I32, I32], [I32])
func_body = [
    local_get(UInt32(0)),
    local_get(UInt32(1)),
    i32_add()
]
func_idx = func(builder, func_type, Tuple{UInt32, ValType}[], func_body)
export_func(builder, "add", UInt32(func_idx))
println("✓ Function added to builder")

println("\nBuilding module...")
wasm_module = build(builder)
println("✓ WasmCore module built")

println("\nEncoding to binary...")
bytes = encode_module(wasm_module)
println("✓ Module encoded to $(length(bytes)) bytes")
println("  Magic: ", bytes[1:4])
println("  Version: ", bytes[5:8])

println("\nFirst 64 bytes of encoded module:")
for i in 1:min(64, length(bytes))
    if (i-1) % 16 == 0
        print("\n  ")
    end
    print(string(bytes[i], base=16, pad=2), " ")
end
println()

println("\nValidating WasmCore-generated module...")
try
    result = validate(engine, bytes)
    println("✓ Validation: $result")
catch e
    println("✗ Validation error: $e")
end

println("\nAttempting to compile...")
try
    rt_module = compile(engine, bytes)
    println("✓ Module compiled successfully!")
catch e
    println("✗ Compilation error: $e")
    if isa(e, WasmtimeException)
        println("  Wasmtime error: ", e.message)
    end
end
