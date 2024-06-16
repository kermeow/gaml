tool
extends EditorPlugin

var ExportPlugin = preload("res://addons/gaml_plugin/ExportPlugin.gd").new()

func _enter_tree():
	ExportPlugin.plugin = self
	add_inspector_plugin(ExportPlugin)
	
func _exit_tree():
	ExportPlugin.file_dialog.queue_free()
	remove_inspector_plugin(ExportPlugin)
