extends Resource

export(String) var mod_id
export(String) var mod_name
export(String) var mod_version
export(Array, String) var mod_dependencies

export(String, DIR) var root_directory

var logger = preload("res://gaml/Logger.gd").new(mod_id)
var hehlib = GAML.hehlib

func _init(_id = "unique_mod_id", _name = "Mod", _version = "1.0.0", _deps = [], _dir = ""):
	mod_id = _id
	mod_name = _name
	mod_version = _version
	mod_dependencies = _deps
	root_directory = _dir

func init(): pass
