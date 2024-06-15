extends Node

const Semver = preload("res://gaml/Semver.gd")

var Version = _gaml_version()
func _gaml_version():
	var version = Semver.new()
	version.parse("0.1.0")
	return version

#func _disable_setter(_value): return

var exec_path = OS.get_executable_path().get_base_dir()
var gaml_path = exec_path.plus_file("gaml")

func _emergency_exit(reason:String = "Unknown"):
	push_error("Fatal GAML error: %s" % reason)
	get_tree().quit()
func _verify_gaml_files():
	var error = "Missing file! %s"
	var dir = Directory.new()
	if !dir.dir_exists(gaml_path): _emergency_exit(error % "gaml")
	if !dir.file_exists(gaml_path.plus_file("game.cfg")): _emergency_exit(error % "game.cfg")
	if !dir.file_exists(gaml_path.plus_file("gaml.cfg")): _emergency_exit(error % "gaml.cfg")
	if !dir.dir_exists(gaml_path.plus_file("mods")): dir.make_dir_recursive(gaml_path.plus_file("mods"))
	if !dir.dir_exists(gaml_path.plus_file("asset-mods")): dir.make_dir_recursive(gaml_path.plus_file("asset-mods"))
	return OK

func _enter_tree():
	get_tree().change_scene("res://gaml/Loading.tscn")
func _ready():
	call_deferred("_load_game")

func _reinit_node(node: Node, recursive: bool = false):
	var method = "notification"
	if recursive: method = "propagate_notification"
	node.call(method, NOTIFICATION_POSTINITIALIZE)
	node.call(method, NOTIFICATION_ENTER_TREE)
	node.call(method, NOTIFICATION_POST_ENTER_TREE)
	node.call(method, NOTIFICATION_READY)

var _is_game_loaded = false
func _load_game():
	if _is_game_loaded: return
	_is_game_loaded = true
	
	_verify_gaml_files()
	
	var game_cfg = ConfigFile.new()
	game_cfg.load(gaml_path.plus_file("game.cfg"))
	
	for key in game_cfg.get_section_keys("autoload"):
		var node = get_node("/root/%s" % key)
		var script_path = game_cfg.get_value("autoload", key).trim_prefix("*")
		var script = load(script_path)
		node.set_script(script)
		call_deferred("_reinit_node", node, false)
	
	var main_scene = game_cfg.get_value("application", "run/main_scene")
	get_tree().change_scene(main_scene)
