class_name Player
extends Entity

const WALK_SPEED = 4.0
const RUN_SPEED = 10.0
const GRAVITY = 18.0

var facing_right := true
var interact_timer := 0.0

@onready var sprite: AnimatedSprite3D = $Visual/AnimatedSprite3D

@export var trigger_area: PlayerTriggerArea
@export var camera : Node3D
@export var IN_COMBAT := false

var is_hovered := false
var input_locked := false

@export var sp: float = 0.0
@export var max_sp: float = 100.0

func _ready():
	print("===PLAYER.gd READY===")
	hp = max_hp
	var cam = get_tree().get_first_node_in_group("camera")
	if cam:
		cam.set_default_target(focus_point)
		
func _physics_process(delta: float) -> void:
	'''
	check if player is not on floor
	get input -> store as vector for direction and magnitude
	forward should not be global north -> or moving camera would break sense of direction
	
	when no input -> wait -> idle animation
	when moving -> walk
	when shift + moving -> run
	'''	
	if !is_on_floor():
		velocity.y -= GRAVITY * delta
		
	if GameStateManager.is_dialog_active():
		input_locked = true
		
	else:
		input_locked = false
		
	var input_dir = Vector2.ZERO
	if !input_locked:
		input_dir = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
		)
	
	var forward = -camera.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var right = camera.global_transform.basis.x
	right.y = 0
	right = right.normalized()

	var direction = (forward * input_dir.y + right * input_dir.x).normalized()
	
	if direction != Vector3.ZERO:
		var angle = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(
			rotation.y,
			angle,
			delta * 10
		)
	var speed = WALK_SPEED
	
	if Input.is_action_pressed("run"):
		speed = RUN_SPEED
		
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	update_sprite(input_dir)
	move_and_slide()

func update_sprite(input_dir: Vector2):
	'''
	update sprite animation as needed
	'''
	if input_dir.x > 0:
		facing_right = true
	elif input_dir.x < 0:
		facing_right = false
		
	sprite.flip_h = !facing_right
	
	var moving = input_dir != Vector2.ZERO
	if moving:
		if Input.is_action_pressed("run"):
			sprite.play("run")
		else:
			sprite.play("walk")
	else:
		sprite.play("idle")
		
		
