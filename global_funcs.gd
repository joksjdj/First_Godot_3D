extends Node


@onready var unsaved_json
func save_json():
	var new_json = JSON.stringify(unsaved_json, "\t")
	var file = FileAccess.open("res://Local_storage/Settings.json", FileAccess.WRITE)
	file.store_string(new_json)
	file.close()


func close_game_safely():
	TcpCommunicationFuncs.message_to_server({"req": "exit"})
	save_json()
	get_tree().quit()

func frame_based_cooldown(frames: int):
	if Global.frame_passed >= frames:
		Global.frame_passed = 0
		return true
	
func _unhandled_input(event: InputEvent) -> void:
	var main_player = get_node_or_null("/root/Main/MainPlayer")
	if main_player:
		if Input.is_key_pressed(KEY_ESCAPE):
				Global.playing = false
				TcpCommunicationFuncs.message_to_server({"req": "exit"})
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
	print("enemies:\n", Global.game_tracking.enemies.keys())
	points.shuffle()
	for enemy in Global.game_tracking.enemies.keys():
		Global.enemies_left += 1
		var spawn = points[Global.enemies_left]
		var enemy_inst = Global.enemy_to_spawn.instantiate()
		spawn.add_child(enemy_inst)
		enemy_inst.id = enemy
		
	Global.spawning_enemies = false

func instantiate_start_menu():
	get_node("/root/Main/Login").queue_free()
	var menu = Global.start_menu.instantiate()
	get_node("/root/Main").add_child(menu)
