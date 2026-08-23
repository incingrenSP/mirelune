class_name NPC
extends Entity

@onready var sprite: AnimatedSprite3D = $Visual/AnimatedSprite3D

@export var routine_enabled := true
@export var routine_point_a: Node3D
@export var routine_point_b: Node3D
@export var wait_time := 10.0
@export var detection_radius := 10.0

const WALK_SPEED := 4.0
const GRAVITY := 18.0

var facing_right := true
var in_dialog := false
var move_target: Vector3

var waiting := false
var routine_direction := 1

func _ready():
	if routine_enabled:
		move_target = routine_point_b.global_position
		
func _physics_process(delta: float) -> void:
	'''
	first check if character is not on ground
	check if npc is in dialog
	if yes -> idle
	if not follow walk routine
	'''
	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0
	
	if GameStateManager.is_dialog_active():
		show_name()
		velocity.x = 0.0
		velocity.z = 0.0
		update_sprite(Vector3.ZERO)
		
	elif routine_enabled:
		walk_routine()
	
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		update_sprite(Vector3.ZERO)
		
	move_and_slide()
	
func _on_dialog_target_changed(target: Node3D) -> void:
	in_dialog = target == self
	
func walk_routine():
	'''
	wait by default -> idle animation -> update sprite
	check distance from position to current move target
	if distance < 1.0 units -> wait -> idle animation -> update sprite
	else move to target at velocity
	'''
	if waiting:
		velocity.x = 0.0
		velocity.z = 0.0
		update_sprite(Vector3.ZERO)
		return
		
	var distance_to_target = global_position.distance_to(move_target)
	
	if distance_to_target < 1.0:
		velocity.x = 0.0
		velocity.z = 0.0
		update_sprite(Vector3.ZERO)
		start_waiting()
		return
		
	var direction = global_position.direction_to(move_target)
	direction.y = 0.0
	direction = direction.normalized()
	
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	update_sprite(direction)
		
func start_waiting():
	'''
	when called wait -> idle animation
	if called in the middle of move routine -> dont change routine
	if called after finishing a routine -> switch routine direction
	'''
	if waiting:
		return
		
	waiting = true
	await get_tree().create_timer(wait_time).timeout
	
	if routine_direction == 1:
		routine_direction = -1
		move_target = routine_point_a.global_position
	else:
		routine_direction = 1
		move_target = routine_point_b.global_position
		
	waiting = false
	
func update_sprite(move_dir: Vector3):
	'''
	update sprite animation based on requirements
	'''
	var horizontal_dir := Vector2(move_dir.x, move_dir.z)
	
	if horizontal_dir.x > 0.01:
		facing_right = true
	elif horizontal_dir.x < -0.01:
		facing_right = false
		
	sprite.flip_h = !facing_right
	
	if horizontal_dir.length() > 0.01:
		sprite.play("walk")
	else:
		sprite.play("idle")

func show_name(visible_state: bool = false):
	'''
	popup for npc name
	'''
	$WorldUI/Label3D.text = "NPC"
	$WorldUI/Label3D.visible = visible_state
