extends Node

# PackedScene
@onready var login_menu: PackedScene = preload("res://addons/login.tscn")
@onready var start_menu: PackedScene = preload("res://addons/start_menu.tscn")
@onready var bullet_to_spawn: PackedScene = preload("res://addons/Bullet.tscn")
@onready var enemy_to_spawn: PackedScene = preload("res://addons/enemy.tscn")

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
@onready var game_tracking = {
	"enemies_left": 0,
	"enemies": null,
}

var tcp := StreamPeerTCP.new()

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
			if tcp.get_available_bytes() > 0:
				var msg = tcp.get_utf8_string(tcp.get_available_bytes())
				var data = JSON.parse_string(msg)
				
				if typeof(data) == TYPE_DICTIONARY:
					var json_body = JSON.parse_string(data.body)
					if json_body:
						data.body = json_body
					
					if data.type in ["login", "signup"]:
						TcpCommunicationFuncs.check_login_and_signup(data)
						
					if data.type in ["game_update"]:
						TcpCommunicationFuncs.store_game_data(data.body)
				else:
					print("\n\nmsg:\n", msg, "\ndata:\n", data)
				
		StreamPeerTCP.STATUS_NONE:
			if Global_funcs.frame_based_cooldown(120):
				var err = tcp.connect_to_host("alexanderpi", 8081)
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
					
		if enemies_left <= 0 and !spawning_enemies and game_tracking.enemies != null:
			spawning_enemies = true
			var points = get_node("/root/Main/Area3D/SpawnPoint").get_children()
			Global_funcs.spawn_enemies(points)

	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Global_funcs.close_game_safely()
