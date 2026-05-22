@tool
extends EditorPlugin

func _enter_tree():
	add_tool_menu_item("Export Collision Map", Callable(self, "_export_map"))

func _exit_tree():
	remove_tool_menu_item("Export Collision Map")

func _export_map():
	var exporter = load("res://addons/map_exporter/export_map.gd").new()

	var map_path = "res://node_3d.tscn"
	var output_path = "res://map_collision.json"

	exporter.export_map_to_json(map_path, output_path)
	print("Collision map exported.")
