extends EditorInspectorPlugin

const Mod = preload("res://gaml/Mod.gd")

var plugin: EditorPlugin

var file_dialog = FileDialog.new()

var mod: Mod

func can_handle(object):
	return object.get_script().get_base_script() == Mod

func parse_begin(object):
	mod = object
	
	var button = Button.new()
	button.text = "Export Mod"
	add_custom_control(button)
	button.connect("pressed", self, "_button_pressed")
	
	file_dialog.mode = FileDialog.MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.add_filter("*.gaml ; GAML Mods")
	file_dialog.filename = mod.mod_id + ".gaml"
	plugin.get_editor_interface().get_base_control().add_child(file_dialog)
	file_dialog.connect("file_selected", self, "_export_mod")

func _button_pressed():
	file_dialog.popup_centered_ratio()

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

func _export_mod(file: String):
	var pck = PCKPacker.new()
	pck.pck_start("tmp.pck")
	pck.add_file(mod.resource_path, mod.resource_path)
	for path in _list_files(mod.root_directory, true, false):
		pck.add_file(path, path)
	pck.flush()
	var pck_file = File.new()
	pck_file.open("tmp.pck", File.READ)
	var pck_buffer = pck_file.get_buffer(pck_file.get_len())
	pck_file.close()
	var dir = Directory.new()
	dir.remove("tmp.pck")
	var mod_file = File.new()
	mod_file.open(file, File.WRITE)
	mod_file.store_buffer(PoolByteArray([0x67, 0x61, 0x6d, 0x6c]))
	mod_file.store_8(preload("res://gaml/GAML.gd").GD_VERSION)
	mod_file.store_16(mod.resource_path.length())
	mod_file.store_string(mod.resource_path)
	mod_file.store_buffer(pck_buffer)
	mod_file.flush()
	mod_file.close()
