extends Node

func _enter_tree():
	get_tree().change_scene("res://gaml/Loading.tscn")

func _ready():
	print("_ready")
