extends Reference

var logger = preload("res://gaml/Logger.gd").new("hehlib")

const special_methods = [
	"_ready",
	"_process",
	"_physics_process",
	"_enter_tree",
	"_exit_tree"
]

var _hooks = {}

func _create_hook(node: Node, method: String):
	var hook_id = "%04x" % _hooks.size()
	_hooks[hook_id] = {"node": node, "method": method}
	return hook_id

func _execute_hook(hook_id:String, caller:Node, params:Array):
	var hook = _hooks.get(hook_id)
	if hook == null: return
	return hook.node.call(hook.method, caller, params)

var script_hooks = {}
var script_special_hooks = {}

func _get_method_hooks(path: String, method: String):
	var hooks = script_hooks.get(path, {})
	var method_hooks = hooks.get(method, {
		"prefixes": [],
		"postfixes": []
	})
	if !hooks.has(method): hooks[method] = method_hooks
	if !script_hooks.has(path): script_hooks[path] = hooks
	return method_hooks
	
func _get_special_hooks(path: String, method: String):
	var hooks = script_special_hooks.get(path, {})
	var method_hooks = hooks.get(method, [])
	if !hooks.has(method): hooks[method] = method_hooks
	if !script_hooks.has(path): script_special_hooks[path] = hooks
	return method_hooks

func _special_warning(method: String):
	if !special_methods.has(method): return
	logger.output("Hooking \"%s\" this way will cause unexpected behaviour! Please use hook_script_special." % method, true)

func hook_script_prefix(path: String, method: String, node: Node, hook_method: String):
	_special_warning(method)
	var hook_id = _create_hook(node, hook_method)
	var method_hooks = _get_method_hooks(path, method)
	method_hooks.prefixes.append(hook_id)

func hook_script_postfix(path: String, method: String, node: Node, hook_method: String):
	_special_warning(method)
	var hook_id = _create_hook(node, hook_method)
	var method_hooks = _get_method_hooks(path, method)
	method_hooks.postfixes.append(hook_id)

func hook_script_special(path: String, method: String, node: Node, hook_method: String):
	var hook_id = _create_hook(node, hook_method)
	var method_hooks = _get_special_hooks(path, method)
	method_hooks.append(hook_id)

func _generate_hooked_script(path: String) -> GDScript:
	var original_script = load(path) as GDScript
	var method_list = _parse_method_list(original_script.get_script_method_list())
	var script = GDScript.new()
	var source = "extends \"%s\"\n" % path
	source += "var hehlib = GAML.hehlib\n"
	var call_index = 0
	if script_hooks.has(path):
		var hooks = script_hooks.get(path)
		for method_name in hooks.keys():
			if !method_list.has(method_name): continue
			var method_hooks = hooks.get(method_name)
			var method = method_list.get(method_name)
			source += "func %s(%s):\n" % [method.name, method.arg_string]
			for prefix in method_hooks.prefixes:
				source += "\tvar _r%02x = hehlib._execute_hook(\"%s\", self, [%s])\n" % [call_index, prefix, method.arg_string]
				call_index += 1
			source += "\tvar _r = .%s(%s)\n" % [method.name, method.arg_string]
			for postfix in method_hooks.postfixes:
				source += "\tvar _r%02x = hehlib._execute_hook(\"%s\", self, [_r,%s])\n" % [call_index, postfix, method.arg_string]
				call_index += 1
			source += "\treturn _r\n"
	if script_special_hooks.has(path):
		var hooks = script_special_hooks.get(path)
		for method_name in hooks.keys():
			var method_hooks = hooks.get(method_name)
			var arg_string = ""
			if method_name == "_process" or method_name == "_physics_process": arg_string = "_delta"
			source += "func %s(%s):\n" % [method_name, arg_string]
			for hook in method_hooks:
				source += "\tvar _r%02x = hehlib._execute_hook(\"%s\", self, [%s])\n" % [call_index, hook, arg_string]
				call_index += 1
	script.source_code = source
	script.reload()
	return script

func _parse_method_list(method_list: Array) -> Dictionary:
	var arg_count = 0
	var methods = {}
	for method_info in method_list:
		var args = {}
		var arg_string = ""
		for arg_info in method_info.args:
			var arg = {"name": "_%04x" % arg_count}
			arg_string += arg.name + ","
			args[arg.name] = arg
			arg_count += 1
		var method = {"name": method_info.name, "args": args, "arg_string": arg_string.trim_suffix(",")}
		methods[method.name] = method
	return methods

var _script_cache = {}

func _get_hooked_script(path: String) -> GDScript:
	if _script_cache.has(path): return _script_cache[path]
	var script = _generate_hooked_script(path)
	_script_cache[path] = script
	return script

func load_script(path: String):
	if has(path):
		logger.output("Getting hooked script %s" % path)
		return _get_hooked_script(path)
	return load(path)

func has(path: String):
	return script_hooks.has(path) or script_special_hooks.has(path)
