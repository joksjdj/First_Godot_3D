extends Node

# Menus
@export var login_menu: PackedScene = preload("res://addons/login.tscn")
@export var start_menu: PackedScene = preload("res://addons/start_menu.tscn")

# Account
@export var id: int
@export var username: String
@export var created_at: String
@export var highscore: int
@export var last_game: int

# Player
@onready var player_health = 3
@onready var heart_container

# Global
@onready var cooldown = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var menu = login_menu.instantiate()
	get_node_or_null("/root/Main").add_child(menu)

	var login_node = get_node("/root/Main/HTTPRequest")
	login_node.request_completed.connect(_on_http_request_request_completed)
	
	var thread = Thread.new()
	
	thread.start(cooldown_thread)

func cooldown_thread():
	while true:
		await get_tree().create_timer(1.0).timeout
		cooldown += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var main_player = get_node_or_null("/root/Main/MainPlayer")
	
	if main_player:
		if player_health < 1:
			main_player.queue_free()
			release_mouse()
			var menu = start_menu.instantiate()
			get_node_or_null("/root/Main").add_child(menu)
		
		if !heart_container:
			heart_container = main_player.get_node_or_null("CanvasLayer/TextureRect/health")
		else:
			var hearts_left = heart_container.get_child_count()
			if hearts_left:
				if player_health < hearts_left:
					var heart = heart_container.get_child(heart_container.get_child_count() - 1)
					heart.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		var main_player = get_node_or_null("/root/Main/MainPlayer")
		if main_player:
			release_mouse()
			main_player.queue_free()
			var menu = start_menu.instantiate()
			get_node_or_null("/root/Main").add_child(menu)

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var text = body.get_string_from_utf8()
	print("Server says: ", text, headers, response_code)
	
	if response_code == 400:
		var err_display = get_node_or_null("/root/Main/Login/Control/VBoxContainer/ErrorContainer")
		if err_display:
			err_display.text = text
			
	if response_code == 200 || response_code == 201:
		var json = JSON.parse_string(text)
		Global.id = json.id
		Global.username = json.username
		Global.created_at = Time.get_datetime_string_from_unix_time(Time.get_unix_time_from_datetime_string(json.created_at))
		Global.highscore = json.highscore
		Global.last_game = json.last_game
		
		get_node_or_null("/root/Main/Login").queue_free()
		var menu = start_menu.instantiate()
		get_node_or_null("/root/Main").add_child(menu)
