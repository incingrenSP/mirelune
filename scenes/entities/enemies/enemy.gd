class_name Enemy
extends Entity

@onready var sprite: AnimatedSprite3D = $Visual/AnimatedSprite3D
@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var patrol_boundary: Area3D = $PatrolZone

@export var routine_enabled := true
@export var wait_time := 1.0
@export var IN_COMBAT := false
@export var attack_duration := 0.5
@export var attack_cooldown := 1.0

const WALK_SPEED := 4.0
const RUN_SPEED := 7.0
const GRAVITY := 18.0
const WAYPOINT_REACHED_DISTANCE := 0.2
const ATTACK_RANGE := 1.5

var attack_timer := 0.0
var attack_cooldown_timer := 0.0
var attack_landed := false

var PATROL_RADIUS : float
var DETECTION_RADIUS : float
var INVESTIGATION_RADIUS : float
var ENGAGE_RADIUS : float

var max_sp := 100.0
var sp := 0.0
var sp_regen_percent := 0.01
var hp_regen_percent := 0.05

var move_target: Vector3
var spawn_position : Vector3

var facing_right := true
var returning_home := false
var is_hovered := false

enum ENEMY_STATES_PASSIVE {
	PATROL,
	SLOW_PATROL,
	WATCH,
	INVESTIGATE,
	DISENGAGE
}

enum ENEMY_STATES_ACTIVE {
	ATTACK,
	CHASE,
	RUN,
	HEAL
}

var passive_state: ENEMY_STATES_PASSIVE = ENEMY_STATES_PASSIVE.PATROL
var active_state: ENEMY_STATES_ACTIVE = ENEMY_STATES_ACTIVE.CHASE
var watch_timer := 0.0
var watch_duration := 0.0

func _ready():
	'''
	get collision shape from patrol zone to extract patrol radius from it
	set spawn_position instead of using global_position
	patrol radius should be fixed so if global_position is used, patrol radius will change
	if enemy is not in combat keep randomly moving around patrol range
	'''
	var hp_bar = $WorldUI/ResourceBars/HPBarFG
	var sp_bar = $WorldUI/ResourceBars/SPBarFG
	hp_bar.material_override = hp_bar.material_override.duplicate()
	sp_bar.material_override = sp_bar.material_override.duplicate()
	
	hp = max_hp
	var collision_shape: CollisionShape3D = patrol_boundary.get_node("Range")
	var shape = collision_shape.shape
	
	if shape is SphereShape3D:
		PATROL_RADIUS = shape.radius
	else:
		push_error("PatrolZone/Range's CollisionShape3D isn't a SphereShape3D; check the shape type.")
	
	DETECTION_RADIUS = 0.8 * PATROL_RADIUS
	INVESTIGATION_RADIUS = 0.6 * PATROL_RADIUS
	ENGAGE_RADIUS = 0.4 * PATROL_RADIUS
	
	spawn_position = global_position
	
	if !IN_COMBAT:
		pick_new_patrol_point()
		
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
	
	if IN_COMBAT:
		_process_active_state(delta)
	
	else:
		_process_passive_state(delta)
		
	move_and_slide()
	
func _process(delta: float) -> void:
	'''
	enemy regens sp only when in combat
	enemy regens hp only when out of combat
	basic idea but modular
	'''
	if IN_COMBAT:
		if sp < max_sp:
			sp = min(sp + sp_regen_percent * max_sp * delta, max_sp)
	elif !IN_COMBAT:
		if hp < max_hp:
			hp = min (hp + hp_regen_percent * max_hp * delta, max_hp)
			
	resource_bar_transition(delta)
	
func _process_passive_state(delta: float):
	var distance_to_player = horizontal_distance_to_player()
	var distance_to_spawn = horizontal_distance_to_spawn()
	
	if distance_to_player <= ENGAGE_RADIUS:
		enter_combat()
		return
		
	if distance_to_player > PATROL_RADIUS:
		# Continue passive behavior
		pass
		
	match passive_state:
		ENEMY_STATES_PASSIVE.PATROL:
			$WorldUI/Label3D.text = "Enemy on PATROL"
			if routine_enabled and walk_routine(WALK_SPEED):
				enter_watch()
			if distance_to_player < DETECTION_RADIUS:
				enter_watch()
				
		ENEMY_STATES_PASSIVE.SLOW_PATROL:
			$WorldUI/Label3D.text = "Enemy on SLOW PATROL"
			if routine_enabled:
				walk_routine(WALK_SPEED)
			if distance_to_player >= DETECTION_RADIUS:
				enter_watch()
			elif distance_to_player < INVESTIGATION_RADIUS:
				enter_watch()
				
		ENEMY_STATES_PASSIVE.WATCH:
			$WorldUI/Label3D.text = "Enemy on WATCH"
			velocity.x = 0.0
			velocity.z = 0.0
			update_sprite(Vector3.ZERO)
			
			watch_timer += delta
			if watch_timer >= watch_duration:
				_resolve_watch(distance_to_player, distance_to_spawn)
				
		ENEMY_STATES_PASSIVE.INVESTIGATE:
			$WorldUI/Label3D.text = "Enemy on INVESTIGATE"
			#print("Enemy in Inevstigate State")
			chase_player(distance_to_player, WALK_SPEED)
			
			if distance_to_player < ENGAGE_RADIUS:
				enter_combat()
			elif distance_to_player > DETECTION_RADIUS or distance_to_spawn > PATROL_RADIUS:
				enter_watch()
				
		ENEMY_STATES_PASSIVE.DISENGAGE:
			$WorldUI/Label3D.text = "Enemy on DISENGAGE"
			#print("Enemy in Disengage State")
			move_target = spawn_position
			var dir = global_position.direction_to(spawn_position)
			dir.y = 0.0
			velocity.x = dir.x * WALK_SPEED
			velocity.z = dir.z * WALK_SPEED
			update_sprite(dir)
			
			if distance_to_spawn <= WAYPOINT_REACHED_DISTANCE:
				global_position.x = spawn_position.x
				global_position.z = spawn_position.z
				
				velocity.x = 0.0
				velocity.y = 0.0
				
				pick_new_patrol_point()
				passive_state = ENEMY_STATES_PASSIVE.PATROL
	
func _process_active_state(delta: float):
	var distance_to_player = global_position.distance_to(player.global_position)
	var distance_to_spawn = global_position.distance_to(spawn_position)
	
	match active_state:
		ENEMY_STATES_ACTIVE.CHASE:
			$WorldUI/Label3D.text = "Enemy on CHASE"
			chase_player(distance_to_player, RUN_SPEED)
			
			if distance_to_player < ATTACK_RANGE and attack_cooldown_timer <= 0.0:
				active_state = ENEMY_STATES_ACTIVE.ATTACK
				var dir = (player.global_position - global_position)
				dir.y = 0.0
				update_sprite(dir.normalized())
				
			elif distance_to_player > PATROL_RADIUS:
				exit_combat()
				
			if attack_cooldown_timer > 0.0:
				attack_cooldown_timer -= delta
		
		ENEMY_STATES_ACTIVE.ATTACK:
			$WorldUI/Label3D.text = "Enemy on ATTACK"
			velocity.x = 0.0
			velocity.z = 0.0
			
			attack_timer += delta
			if not attack_landed and attack_timer >= attack_duration * 0.5:
				attack_landed = true
				
			if attack_timer >= attack_duration:
				attack_timer = 0.0
				attack_landed = false
				attack_cooldown_timer = attack_cooldown
				active_state = ENEMY_STATES_ACTIVE.CHASE
				
		ENEMY_STATES_ACTIVE.HEAL:
			$WorldUI/Label3D.text = "Enemy on HEAL"
			active_heal()

func active_heal():
	active_state = ENEMY_STATES_ACTIVE.CHASE
	if hp < 0.1 * max_hp and randf() >= 0.3:
		hp = min(hp + 100.0, max_hp)

func enter_watch(duration: float = wait_time, return_home: bool = false) -> void:
	passive_state = ENEMY_STATES_PASSIVE.WATCH
	
	watch_timer = 0.0
	watch_duration = duration
	returning_home = returning_home
	
	velocity.x = 0.0
	velocity.z = 0.0

func horizontal_distance_to_player() -> float:
	var offset := player.global_position - global_position
	offset.y = 0.0
	return offset.length()
	
func horizontal_distance_to_spawn() -> float:
	var offset := spawn_position - global_position
	offset.y = 0.0
	return offset.length()

func _resolve_watch(distance_to_player: float, distance_to_spawn: float):
	if  distance_to_player < INVESTIGATION_RADIUS:
		returning_home = false
		passive_state = ENEMY_STATES_PASSIVE.INVESTIGATE
		
	elif distance_to_spawn > PATROL_RADIUS:
		passive_state = ENEMY_STATES_PASSIVE.DISENGAGE
		
	elif distance_to_player < DETECTION_RADIUS:
		passive_state = ENEMY_STATES_PASSIVE.SLOW_PATROL
		
	else:
		pick_new_patrol_point()
		passive_state = ENEMY_STATES_PASSIVE.PATROL

func enter_combat():
	if IN_COMBAT:
		return
	
	IN_COMBAT = true
	resource_bar_visibility()
	
	CombatManager.enter_combat(self)
	active_state = ENEMY_STATES_ACTIVE.CHASE
	
func exit_combat():
	if !IN_COMBAT:
		return
		
	IN_COMBAT = false
	resource_bar_visibility()
	
	CombatManager.exit_combat(self)
	enter_watch(5.0, true)

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
		
func pick_new_patrol_point():
	var random_angle = randf() * TAU
	var random_distance = sqrt(randf()) * PATROL_RADIUS
	
	move_target = spawn_position + Vector3(
		cos(random_angle) * random_distance,
		0,
		sin(random_angle) * random_distance
	)
	
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
		
	if active_state == ENEMY_STATES_ACTIVE.ATTACK:
		sprite.play("attack")
		
func resource_bar_transition(delta: float):
	var target_hp_pct = hp / max_hp
	var target_sp_pct = sp / max_sp
	
	displayed_hp_pct = move_toward(
		displayed_hp_pct,
		target_hp_pct,
		bar_smooth_speed * delta
	)
	displayed_sp_pct = move_toward(
		displayed_sp_pct,
		target_sp_pct,
		bar_smooth_speed * delta
	)
	
	update_hp_bar()
	update_sp_bar()
		
func resource_bar_visibility(text: String = "Enemy"):
	$WorldUI/Label3D.text = text
	$WorldUI/Label3D.visible = IN_COMBAT or is_hovered
	$WorldUI/ResourceBars.visible = IN_COMBAT or is_hovered

func update_hp_bar():
	($WorldUI/ResourceBars/HPBarFG.material_override as ShaderMaterial).set_shader_parameter("fill_amount", displayed_hp_pct)

func update_sp_bar():
	($WorldUI/ResourceBars/SPBarFG.material_override as ShaderMaterial).set_shader_parameter("fill_amount", displayed_sp_pct)
