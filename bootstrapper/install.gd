extends SceneTree

func create_configs(exec_path):
	var override_path = exec_path + "/override.cfg"
	var gaml_path = exec_path + "/gaml"
	print("Saving configs to " + gaml_path )
	ProjectSettings.save_custom(gaml_path + "/override.cfg")
	var dir = Directory.new()
	dir.rename(gaml_path + "/override.cfg", gaml_path + "/game.cfg")
	var gaml = ConfigFile.new()
	gaml.load(gaml_path + "/game.cfg")

	gaml.set_value("GAML", "GAML", true)
	for key in gaml.get_section_keys("autoload"):
		var original = gaml.get_value("autoload", key)
		var new = gaml_path + "/ghost.gd"
		if original.begins_with("*"):
			new = "*" + new
		gaml.set_value("autoload", key, new)
	gaml.set_value("autoload", "GAML", "*" + gaml_path + "/ghost.gd")
	gaml.set_value("autoload", "GAMLB", gaml_path + "/bootstrapper.gd")

	gaml.set_value("application", "run/main_scene", gaml_path + "/ghost.tscn")

	gaml.save(gaml_path + "/gaml.cfg")
	print("Copying gaml.cfg to override.cfg")
	gaml.save(override_path)

func _init():
	print(" -- GAML INSTALLER -- ")
	var path = OS.get_executable_path().get_base_dir()
	if !ProjectSettings.get_setting("GAML/GAML"):
		print("Installing GAML")
		create_configs(path)
	else:
		print("Removing GAML")
		var dir = Directory.new()
		dir.remove(path + "/gaml/game.cfg")
		dir.remove(path + "/gaml/gaml.cfg")
		dir.remove(path + "/override.cfg")
	quit()