# The SDK modules are compile-time declarations. Load the minimal test host
# after compilation, without replacing the SDK's event payload structs.
previous_conflict = Code.get_compiler_option(:ignore_module_conflict)
Code.put_compiler_option(:ignore_module_conflict, true)

try do
  __DIR__
  |> Path.join("support/host/*.exs")
  |> Path.wildcard()
  |> Enum.each(&Code.require_file/1)
after
  Code.put_compiler_option(:ignore_module_conflict, previous_conflict)
end

ExUnit.start()
