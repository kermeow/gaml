extends Node

const GD_VERSION: int = 3

var exec_path = OS.get_executable_path().get_base_dir()
var gaml_path = exec_path.plus_file("gaml")

var paths = {
	"logs": gaml_path.plus_file("logs"),
	"mods": gaml_path.plus_file("mods"),
	"asset_mods": gaml_path.plus_file("asset-mods"),
}

var hehlib = preload("res://hehlib/hehlib.gd").new()
var asset_loader = preload("res://gaml/RuntimeAssetLoader.gd").new()
var logger = preload("res://gaml/Logger.gd").new("gaml")

#func _disable_setter(_value): return

# Utility functions
func _emergency_exit(reason: String = "Unknown"):
	var error = "Fatal GAML error: %s" % reason
	logger.output(error)
	logger.output("Quitting")
	push_error(error)
	get_tree().call_deferred("quit")

func _verify_gaml_files():
	var error = "Missing file! %s\nYou might need to reinstall GAML."
	var dir = Directory.new()
	if !dir.dir_exists(gaml_path): _emergency_exit(error % "gaml")
	if !dir.file_exists(gaml_path.plus_file("game.cfg")): _emergency_exit(error % "game.cfg")
	if !dir.file_exists(gaml_path.plus_file("gaml.cfg")): _emergency_exit(error % "gaml.cfg")
	if !dir.dir_exists(paths.logs): dir.make_dir_recursive(paths.logs)
	if !dir.dir_exists(paths.mods): dir.make_dir_recursive(paths.mods)
	if !dir.dir_exists(paths.asset_mods): dir.make_dir_recursive(paths.asset_mods)
	return OK

func _reinit_node(node: Node, recursive: bool = false):
	logger.output("Re-initialise node %s" % node)
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
		logger.output("Enabling autoload %s" % key)
		var node = get_node("/root/%s" % key)
		var script_path = game_cfg.get_value("autoload", key).trim_prefix("*")
		var script = load(script_path)# hehlib.load_script(script_path)
		node.set_script(script)
		call_deferred("_reinit_node", node, false)
	
	logger.output("Change to main scene")
	var main_scene = game_cfg.get_value("application", "run/main_scene")
	get_tree().change_scene(main_scene)

# Asset Modding
func _load_asset_mods():
	var dir = Directory.new()
	for path in _list_files(paths.asset_mods, false, true):
		if !dir.dir_exists(path): continue
		logger.output("Loading asset mod from %s" % path)
		_load_asset_mod(path)
func _load_asset_mod(path):
	var files = _list_files(path, true)
	for file in files:
		var local_path = file.trim_prefix(path).trim_prefix("/")
		var resource = asset_loader.load_asset(file)
		var res_path = "res://" + local_path
		resource.take_over_path(res_path)

# GAML Mods
const Mod = preload("res://gaml/Mod.gd")
const Semver = preload("res://gaml/Semver.gd")

var mods = {}

func _load_mods():
	for path in _list_files(paths.mods):
		if path.get_extension() != "gaml": continue
		_load_mod(path)

func _load_mod(path: String):
	var short_name = path.get_file()
	var file = File.new()
	file.open(path, File.READ)
	if file.get_buffer(4) != PoolByteArray([0x67, 0x61, 0x6d, 0x6c]): return
	if file.get_8() != GD_VERSION:
		logger.output("Not loading %s, Godot version mismatch" % short_name)
		return
	logger.output("Loading %s" % short_name)
	var mod_path = file.get_buffer(file.get_16()).get_string_from_ascii()
	var pck_position = file.get_position()
	ProjectSettings.load_resource_pack(path, false, pck_position)
	var mod = load(mod_path) as Mod
	mods[mod.mod_id] = mod
	mod.logger = preload("res://gaml/Logger.gd").new(mod.mod_id)

var _initialised_mods = []
var _dependency_cycle = []

func _init_mods():
	for mod_id in mods.keys():
		if mod_id in _initialised_mods: continue
		_init_mod(mods[mod_id])

func _init_mod(mod: Mod):
	if _dependency_cycle.has(mod.mod_id):
		logger.output("Cyclic dependency! Skipping. (%s: %s)" % [mod.mod_id, _dependency_cycle])
		return
	_dependency_cycle.append(mod.mod_id)
	for dependency in mod.mod_dependencies:
		if !mods.has(dependency):
			logger.output("Dependency %s of %s is missing! Mod will not be loaded." % [dependency, mod.mod_id])
			return
		if !_initialised_mods.has(dependency): _init_mod(mods[dependency])
	logger.output("Initialising %s" % mod.mod_id)
	mod.init()
	_dependency_cycle.erase(mod.mod_id)

# Main
func _enter_tree():
	get_tree().change_scene("res://gaml/Loading.tscn")

func _ready():
	_load_asset_mods()
	_load_mods()
	_init_mods()
	hehlib.inject_hooked_scripts()
	call_deferred("_load_game")
