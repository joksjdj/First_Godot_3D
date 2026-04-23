# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D

@onready var health = 3

@onready var thread = Thread.new()

## Can we move around?
@export var can_move : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = true

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 9
## How fast do we run?
@export var sprint_speed : float = 10.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "Left"
## Name of Input Action to move Right.
@export var input_right : String = "Right"
## Name of Input Action to move Forward.
@export var input_forward : String = "Forward"
## Name of Input Action to move Backward.
@export var input_back : String = "Backwards"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "Sprint"

## Bullet & Grappling
@onready var camera = $Head/Camera3D

@onready var grappling_pos
@onready var is_grappling = false

@onready var mouse_captured : bool = false
@onready var look_rotation : Vector2
@onready var move_speed : float = 0.0
@onready var freeflying : bool = false

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider

## UI Elements
@onready var fps_value: Label = $CanvasLayer/TextureRect/VBoxContainer/fps/value

func _ready() -> void:
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	
	thread.start(_health_monitor)

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		free_queue()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)

func _physics_process(delta: float) -> void:
	
	# Apply gravity to velocity
	if not is_on_floor():
		velocity += get_gravity() * 2 * delta

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity

	# Modify speed based on sprinting
	if can_sprint and Input.is_action_pressed(input_sprint):
			move_speed = sprint_speed
			smooth_fov(85, 0.5)
	else:
		move_speed = base_speed
		smooth_fov(75, 0.5)

	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
		
	if is_grappling == true:
		position.x = lerp(position.x, grappling_pos.x, 0.01)
		position.z = lerp(position.z, grappling_pos.z, 0.01)
		position.y = lerp(position.y, grappling_pos.y, 0.02)
	# Use velocity to actually move
	move_and_slide()
	
	var fps = Engine.get_frames_per_second()
	fps_value.text = str(fps)
		

@onready var hearts = $CanvasLayer/TextureRect/health
@onready var hearts_left = hearts.get_child_count()
@onready var await_health_change = false
@onready var alive = true
func _health_monitor():
	while alive:
		if health < 1:
			alive = false
			call_deferred("free_queue")
			
		if !alive:
			return
		
		if health < hearts_left and !await_health_change:
			await_health_change = true
			call_deferred("health_change")
			
		OS.delay_msec(50)

func health_change():
	hearts_left -= 1
	var heart = hearts.get_child(hearts.get_child_count() - 1)
	heart.queue_free()
	await_health_change = false
	
	
func free_queue():
	release_mouse()
	var area = get_parent().get_node("Area2D")
	area.visible = true
	area.get_node("Control").MOUSE_FILTER_STOP
	queue_free()

## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true
func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


func smooth_fov(target_fov: float, duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(camera, "fov", target_fov, duration)


func _input(event):
	if event.is_action_pressed("MouseLeft"):
		spawn_bullet()
		
	if event.is_action_pressed("MouseRight"):
		grappling()
		
@export var object_to_spawn: PackedScene
func spawn_bullet():
	var obj = object_to_spawn.instantiate()
	var area = get_parent().get_node("Area3D")
	area.add_child(obj)
	obj.global_transform.basis = camera.global_transform.basis.orthonormalized()
	obj.global_position = camera.global_transform.origin + -camera.global_transform.basis.z

@export var grappling_to_spawn: PackedScene
func grappling():
	var obj = grappling_to_spawn.instantiate()
	add_child(obj)
	obj.global_transform.basis = camera.global_transform.basis.orthonormalized()
	obj.global_position = camera.global_transform.origin + -camera.global_transform.basis.z
