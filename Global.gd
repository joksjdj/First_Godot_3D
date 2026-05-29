extends Node

# PackedScene
@export var login_menu: PackedScene = preload("res://addons/login.tscn")
@export var start_menu: PackedScene = preload("res://addons/start_menu.tscn")
@export var bullet_to_spawn: PackedScene = preload("res://addons/Bullet.tscn")
@export var enemy_to_spawn: PackedScene = preload("res://addons/enemy.tscn")

# Account
@export var id: int
@export var username: String
@export var created_at: String
@export var highscore: int
@export var last_game: int

# Player
@onready var player_health = 3
@onready var heart_container
@onready var player_head_pos: Vector3
var player_last_hit: int = 0
var player_rot: Vector3

# Global tracking
@onready var cooldown = 0
var enemies_left: int = 0
var spawning_enemies: bool = false
var score: int = 0
var main_player: CharacterBody3D
@onready var mouse_captured : bool = false
var playing: bool = false
@onready var frame_passed := 0

var tcp := StreamPeerTCP.new()
var connected := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var menu = login_menu.instantiate()
	get_node_or_null("/root/Main").add_child(menu)
	
	var thread = Thread.new()
	
	thread.start(cooldown_thread)

func cooldown_thread():
	while true:
		await get_tree().create_timer(1.0).timeout
		cooldown += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	frame_passed += 1
	
	tcp.poll()
	match tcp.get_status():
		StreamPeerTCP.STATUS_CONNECTING:
			if Global_funcs.frame_based_cooldown(180):
				print("Trying to connect...")
			
		StreamPeerTCP.STATUS_CONNECTED:
			if Global_funcs.frame_based_cooldown(120):
				tcp.put_data("Hello server\n".to_utf8_buffer())
			if tcp.get_available_bytes() > 0:
				var msg = tcp.get_utf8_string(tcp.get_available_bytes())
				print("Server says:", msg)
				
		StreamPeerTCP.STATUS_NONE:
			if Global_funcs.frame_based_cooldown(120):
				var err = tcp.connect_to_host("alexanderpi", 8080)
				if err == OK:
					print("Connecting...")
				else:
					print("Failed to start connection:", err)
				

	main_player = get_node_or_null("/root/Main/MainPlayer")
	
	if main_player:
		player_head_pos = main_player.get_node("Head").global_position
		if player_health < 1:
			main_player.queue_free()
			Global_funcs.release_mouse()
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
					
					
		if enemies_left <= 0 and !spawning_enemies:
			spawning_enemies = true
			var points = get_node("/root/Main/Area3D/SpawnPoint").get_children()
			Global_funcs.spawn_enemies(points)

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

	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Global_funcs.close_game_safely()
