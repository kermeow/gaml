extends Node

var exec_path = OS.get_executable_path().get_base_dir()
var gaml_path = exec_path.plus_file("gaml")

var paths = {
	"logs": gaml_path.plus_file("logs"),
	"mods": gaml_path.plus_file("mods"),
	"asset_mods": gaml_path.plus_file("asset-mods"),
}

const Semver = preload("res://gaml/Semver.gd")

var Version = _gaml_version()
func _gaml_version():
	var version = Semver.new()
	version.parse("0.1.0")
	return version
var GodotVersion = _godot_version()
func _godot_version():
	var version = Semver.new()
	var engine_version = Engine.get_version_info()
	version.major = engine_version.major
	version.minor = engine_version.minor
	version.patch = engine_version.patch
	return version

const RuntimeAssetLoader = preload("res://gaml/RuntimeAssetLoader.gd")
var asset_loader = RuntimeAssetLoader.new()

const Logger = preload("res://gaml/Logger.gd")
var Log = Logger.new("gaml")

#func _disable_setter(_value): return

# Utility functions
func _emergency_exit(reason: String = "Unknown"):
	var error = "Fatal GAML error: %s" % reason
	Log.output(error)
	Log.output("Quitting")
	push_error(error)
	get_tree().call_deferred("quit")

func _verify_gaml_files():
	var error = "Missing file! %s"
	var dir = Directory.new()
	if !dir.dir_exists(gaml_path): _emergency_exit(error % "gaml")
	if !dir.file_exists(gaml_path.plus_file("game.cfg")): _emergency_exit(error % "game.cfg")
	if !dir.file_exists(gaml_path.plus_file("gaml.cfg")): _emergency_exit(error % "gaml.cfg")
	if !dir.dir_exists(paths.logs): dir.make_dir_recursive(paths.logs)
	if !dir.dir_exists(paths.mods): dir.make_dir_recursive(paths.mods)
	if !dir.dir_exists(paths.asset_mods): dir.make_dir_recursive(paths.asset_mods)
	return OK

func _reinit_node(node: Node, recursive: bool = false):
	Log.output("Re-initialise node %s" % node)
	var method = "notification"
	if recursive: method = "propagate_notification"
	node.call(method, NOTIFICATION_POSTINITIALIZE)
	node.call(method, NOTIFICATION_ENTER_TREE)
	node.call(method, NOTIFICATION_POST_ENTER_TREE)
	node.call(method, NOTIFICATION_READY)

func _list_files(path: String, recursive: bool = false, include_dirs: bool = false):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, false)
	var file = dir.get_next()
	while !file.empty():
		var full_path = path.plus_file(file)
		if dir.dir_exists(full_path):
			if include_dirs: files.append(full_path)
			if recursive: files.append_array(_list_files(full_path, true, include_dirs))
		if dir.file_exists(full_path):
			files.append(full_path)
		file = dir.get_next()
	return files

# Game (re)Loading
var _is_game_loaded = false
func _load_game():
	if _is_game_loaded: return
	_is_game_loaded = true
	
	_verify_gaml_files()
	
	var game_cfg = ConfigFile.new()
	game_cfg.load(gaml_path.plus_file("game.cfg"))
	
	for key in game_cfg.get_section_keys("autoload"):
		Log.output("Enabling autoload %s" % key)
		var node = get_node("/root/%s" % key)
		var script_path = game_cfg.get_value("autoload", key).trim_prefix("*")
		var script = load(script_path)
		node.set_script(script)
		call_deferred("_reinit_node", node, false)
	
	Log.output("Change to main scene")
	var main_scene = game_cfg.get_value("application", "run/main_scene")
	get_tree().change_scene(main_scene)

# Asset Modding
func _load_asset_mods():
	var dir = Directory.new()
	for path in _list_files(paths.asset_mods, false, true):
		if !dir.dir_exists(path): continue
		Log.output("Loading asset mod from %s" % path)
		_load_asset_mod(path)
func _load_asset_mod(path):
	var files = _list_files(path, true)
	for file in files:
		var local_path = file.trim_prefix(path).trim_prefix("/")
		var resource = asset_loader.load_asset(file)
		var res_path = "res://" + local_path
		resource.take_over_path(res_path)

# Main
func _enter_tree():
	get_tree().change_scene("res://gaml/Loading.tscn")

func _ready():
	_load_asset_mods()
	call_deferred("_load_game")
