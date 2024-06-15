extends SceneTree

var hehlib = GAML.hehlib

func _init():
	connect("node_added", self, "_replace_node_scripts")

func _replace_node_scripts(node: Node):
	var node_script = node.get_script()
	if node_script != null:
		if hehlib.has(node_script.resource_path):
			var properties = {}
			for property_info in node_script.get_script_property_list():
				properties[property_info.name] = node.get(property_info.name)
			node.set_script(hehlib.load_script(node_script.resource_path))
			for property_key in properties:
				node.set(property_key, properties.get(property_key))
	if node.get_child_count() > 0:
		for child in node.get_children():
			_replace_node_scripts(child)
