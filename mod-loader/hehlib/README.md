# Harmony-esque Hooking Library
**hehlib** gives mod developers the ability to hook script methods, similar to Harmony for Unity.

This gives mod developers more freedom without needing to repackage decompiled pieces of the game they're modding. In turn, multiple mods can hook parts of the same script, even the same methods, without any issues.

## Using hehlib
>[!NOTE]
>This guide assumes you are using **GAML**. Other mod loaders are not officially supported.

### Prefixes
Prefix hooks run just before the original method.
```gdscript
# hehlib.hook_script_prefix(original_script_path, original_method, callback_node, callback_method)
hehlib.hook_script_prefix("res://path/to/original/script.gd", "method_to_hook", self, "hook_callback")
```
### Postfixes
Postfix hooks run the same as prefix hooks, except they run after the original method instead of before it.
Unlike prefix hooks, postfix hooks can access the original method's result from the HookContext.
```gdscript
# hehlib.hook_script_postfix(original_script_path, original_method, callback_node, callback_method)
hehlib.hook_script_postfix("res://path/to/original/script.gd", "method_to_hook", self, "hook_callback")
```
### Special hooks
Special hooks add functionality to the script. They don't have "original methods" and are intended for use with methods that have weird functionality in GDScript.
These special methods are:
- _ready
- _process
- _physics_process
- _enter_tree
- _exit_tree

Attempting to hook these methods with prefixes or postfixes will work, but will cause the original method to run twice due to how the engine handles them.
```gdscript
# hehlib.hook_script_special(original_script_path, original_method, callback_node, callback_method)
hehlib.hook_script_special("res://path/to/original/script.gd", "method_to_hook", self, "hook_callback")
```
### HookContext
When a hook is called, its only argument is the HookContext.
The HookContext provides access to the caller, method name, arguments, and lets you change the result of the hooked method.
```gdscript
func hook_callback(context):
  print(context.caller) # Prints whatever Object called the hooked method
  print(context.arguments) # Prints the arguments passed to the hooked method
  print(context.get_result()) # Prints the result of the original method (this will be Null in a prefix unless the result has been changed)
  context.result = "Hello, world!" # Changes the result of the hooked method
```
