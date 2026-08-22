class_name Enemy
extends Entity

@onready var sprite: AnimatedSprite3D = $Visual/AnimatedSprite3D
@onready var player: Player = get_tree().get_first_node_in_group("player")

@export var routine_enabled := true
@export var wait_time := 1.0
@export var IN_COMBAT := false

const WALK_SPEED := 4.0
const RUN_SPEED := 7.0
const GRAVITY := 18.0
const WAYPOINT_REACHED_DISTANCE := 0.2
const ATTACK_RANGE := 1.5

var max_sp := 100.0
var sp := 0.0
var sp_regen_percent := 0.01
var hp_regen_percent := 0.05

var move_target: Vector3
var spawn_position : Vector3

var facing_right := true
var is_hovered := false

var watch_timer := 0.0
var watch_duration := 0.0

func _ready():
	'''
	get collision shape from patrol zone to extract patrol radius from it
	set spawn_position instead of using global_position
	patrol radius should be fixed so if global_position is used, patrol radius will change
	if enemy is not in combat keep randomly moving around patrol range
	'''
	spawn_position = global_position
	
	if !IN_COMBAT:
		velocity.x = 0.0
		velocity.z = 0.0
		
		update_sprite(Vector3.ZERO)
		
func _physics_process(delta: float) -> void:
	'''
	check if enemy is on floor
	if enemy is in combat -> ENEMY_ACTIVE = on ENEMY_PASSIVE = off
	if enemy is not in combat -> ENEMY_ACTIVE = off ENEMY_PASSIVE = on
	
	when in combat player should be in engage range
	patrol radius is 10.0 units -> enemy ignores player
	detection radius is 8.0 units (80%) -> enemy notices player -> waiting time increases between patrols
	investigation radius is 6.0 units (60%) -> enemy walks towards player
	engage radius is 4.0 units (40%) -> enemy actively chases and attacks player -> enemy enters IN_COMBAT + ENEMY_ACTIVE
	
	IN_BATTLE only off when player is out of patrol radius
	enemy waits for wait_time and enters ENEMY_PASSIVE, !IN_BATTLE
	
	patrol radius is fixed others are dynamic but doesn't span outside the patrol radius
	
	'''	
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	
	if GameStateManager.is_dialog_active():
		velocity.x = 0.0
		velocity.z = 0.0
		update_sprite(Vector3.ZERO)
	
	move_and_slide()

func walk_routine(move_speed: float) -> bool:
	'''
	activates regardless of ENEMY_ACTIVE or ENEMY_PASSIVE
	move target switches between active patrol point or player location
	when called enemy moves to target
	'''
	var to_target := move_target - global_position
	to_target.y = 0.0
	
	var distance := to_target.length()
	
	if distance <= WAYPOINT_REACHED_DISTANCE:
		global_position.x = move_target.x
		global_position.z = move_target.z
		
		velocity.x = 0.0
		velocity.z = 0.0
		update_sprite(Vector3.ZERO)
		return true
		
	var direction = to_target.normalized()
	
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	
	update_sprite(direction)
	return false
	
func chase_player(distance: float, move_speed: float):
	'''
	only called when player enters investigation radius
	if IN_BATTLE -> move_speed = RUN_SPEED
	if !IN_BATTLE -> move_speed = WALK_SPEED
	'''	
	if distance > ATTACK_RANGE:
		var target_dir = (player.global_position - global_position).normalized()
		velocity.x = target_dir.x * move_speed
		velocity.z = target_dir.z * move_speed
		velocity.y = 0.0
		update_sprite(target_dir)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		update_sprite(Vector3.ZERO)
		
func update_sprite(move_dir: Vector3):
	var horizontal_dir := Vector2(move_dir.x, move_dir.z)
	
	if horizontal_dir.x > 0.01:
		facing_right = true
	elif horizontal_dir.x < -0.01:
		facing_right = false
		
	sprite.flip_h = !facing_right
	
	if horizontal_dir.length() > 0.01:
		if IN_COMBAT:
			sprite.play("run")
		else:
			sprite.play("walk")
	else:
		sprite.play("idle")
		
