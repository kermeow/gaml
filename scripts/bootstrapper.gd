extends Node

# Loads GAML and nothing else

func _init():
	var dir = Directory.new()
	var path = OS.get_executable_path().get_base_dir()
	var gaml_pck = path.plus_file("gaml/GAML.pck")
	if !dir.file_exists(gaml_pck):
		print("GAML.pck is missing!")
		get_tree().quit()
	ProjectSettings.load_resource_pack(gaml_pck)
	GAML.set_script(load("res://gaml/GAML.gd"))
	GAML.bootstrap_finish()