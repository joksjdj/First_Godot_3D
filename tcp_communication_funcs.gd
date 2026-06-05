extends Node

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
		
		Global_funcs.instantiate_start_menu()
		
	elif data.status in [400.0]:
		var err_display = get_node_or_null("/root/Main/Login/Control/VBoxContainer/ErrorContainer")
		if err_display:
			err_display.text = data.body
