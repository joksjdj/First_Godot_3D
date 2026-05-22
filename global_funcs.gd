extends Node


@onready var unsaved_json
func save_json():
	var new_json = JSON.stringify(unsaved_json, "\t")
	var file = FileAccess.open("res://Local_storage/Settings.json", FileAccess.WRITE)
	file.store_string(new_json)
	file.close()


func close_game_safely():
	Global.ws.close()
	save_json()
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	var main_player = get_node_or_null("/root/Main/MainPlayer")
	if main_player:
		if Input.is_key_pressed(KEY_ESCAPE):
				Global.playing = false
				print(get_tree().get_nodes_in_group("Play_packets"))
				release_mouse()
				var play_packets = get_tree().get_nodes_in_group("Play_packets")
				for node in play_packets:
					node.queue_free()
				var menu = Global.start_menu.instantiate()
				get_node_or_null("/root/Main").add_child(menu)
				
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			capture_mouse()

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Global.mouse_captured = true
func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Global.mouse_captured = false

func spawn_bullet(head):
	var bullet = Global.bullet_to_spawn.instantiate()
	var area = get_node("/root/Main")
	area.add_child(bullet)
	bullet.global_transform.basis = head.global_transform.basis.orthonormalized()
	bullet.global_position = head.global_transform.origin + -head.global_transform.basis.z

func spawn_enemies(points):
	points.shuffle()
	for spawn in points:
		if Global.enemies_left >= 7:
			break
		Global.enemies_left += 1
		var enemy = Global.enemy_to_spawn.instantiate()
		enemy.walk_path = spawn.get_node("Path3D/PathFollow3D")
		enemy.global_position = spawn.get_node("Path3D/PathFollow3D").global_position
		enemy.set_collision_layer_value(5, true)
		spawn.add_child(enemy)
		
	Global.spawning_enemies = false
		
func message_to_server(req: String):
	if Global.ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		print("sending msg func")
		var msg = {
			"id": str(Global.id),
			"req": str(req),
			"lobby_id": "1"
		}
		Global.ws.send_text(JSON.stringify(msg))
