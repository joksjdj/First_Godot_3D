@tool
extends Node

func get_all_collision_shapes(node: Node) -> Array:
	var result := []
	for child in node.get_children():
		if child is CollisionShape3D:
			result.append(child)
		result += get_all_collision_shapes(child)
	return result

func extract_collision_data(map_root: Node) -> Array:
	var shapes := get_all_collision_shapes(map_root)
	var data := []

	for shape_node in shapes:
		var shape = shape_node.shape
		var xform = shape_node.global_transform

		if shape is BoxShape3D:
			data.append({
				"type": "box",
				"position": xform.origin,
				"size": shape.size,
				"basis": xform.basis
			})

		elif shape is SphereShape3D:
			data.append({
				"type": "sphere",
				"position": xform.origin,
				"radius": shape.radius
			})

		elif shape is CapsuleShape3D:
			data.append({
				"type": "capsule",
				"position": xform.origin,
				"radius": shape.radius,
				"height": shape.height
			})

		elif shape is ConcavePolygonShape3D:
			data.append({
				"type": "concave",
				"position": xform.origin,
				"basis": xform.basis,
				"faces": shape.data
			})

		elif shape is ConvexPolygonShape3D:
			data.append({
				"type": "convex",
				"position": xform.origin,
				"basis": xform.basis,
				"points": shape.points
			})

	return data

func export_map_to_json(map_path: String, output_path: String):
	var map = load(map_path).instantiate()
	add_child(map)

	var data = extract_collision_data(map)
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	print("Exported collision map to: ", output_path)
