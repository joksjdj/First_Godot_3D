extends Node


@onready var unsaved_json
func save_json():
	var new_json = JSON.stringify(unsaved_json, "\t")
	var file = FileAccess.open("res://Local_storage/Settings.json", FileAccess.WRITE)
	file.store_string(new_json)
	file.close()


func close_game_safely():
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


## SERVER Communication

func message_to_server(req: Dictionary):
	if  Global.tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		print(req)
		var json_text := JSON.stringify(req) + "\n"
		Global.tcp.put_data(json_text.to_utf8_buffer())
	else:
		print("Something went wrong")

func check_login_and_signup(data):
	if data.status in [200.0, 201.0]:
		var json = data.body
		Global.id = json.id
		Global.username = json.username
		Global.created_at = Time.get_datetime_string_from_unix_time(Time.get_unix_time_from_datetime_string(json.created_at))
		Global.highscore = json.highscore
		Global.last_game = json.last_game
		
		get_node("/root/Main/Login").queue_free()
		var menu = Global.start_menu.instantiate()
		add_child(menu)
		
	elif data.status in [400.0]:
		var err_display = get_node_or_null("/root/Main/Login/Control/VBoxContainer/ErrorContainer")
		if err_display:
			err_display.text = data.body
