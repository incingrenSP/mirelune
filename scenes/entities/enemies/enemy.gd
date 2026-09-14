class_name Enemy
extends Entity

enum AnimType {
	LIGHT,
	STRONG,
	HEAVY
}

@onready var sprite: AnimatedSprite3D = $Visual/AnimatedSprite3D
@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var patrol_boundary: Area3D = $PatrolZone

@onready var stat_component: StatComponent = $StatComponent
@onready var hitbox: Hitbox = $Hitbox
@onready var targeting_controller: SkillTargetingController = $SkillTargetingController
@onready var casting_progress_ui: Node3D = $WorldUI/ResourceBars/CastingUI

@onready var guard: Guard = $Guard

@export var enemy_stats: EntityStats
@export var enemy_skills: EntitySkills

@export var routine_enabled := true
@export var wait_time := 1.0
@export var IN_COMBAT := false
@export var attack_duration := 0.5
@export var attack_cooldown := 3.0

const WALK_SPEED := 4.0
const RUN_SPEED := 7.0
const GRAVITY := 18.0
const WAYPOINT_REACHED_DISTANCE := 0.2
const ATTACK_RANGE := 1.5
const REACTION_TIMER := 0.35

var attack_timer := 0.0
var attack_cooldown_timer := 0.0
var attack_landed := false

var movement_locked := false
var casting_state := false
var attack := false
var ranged_attack_started := false

var skill_use_cd: float = 0.5
var skill_use_timer: float = 0.0
var anim: AnimType = AnimType.LIGHT

var PATROL_RADIUS : float
var DETECTION_RADIUS : float
var INVESTIGATION_RADIUS : float
var ENGAGE_RADIUS : float

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
	RANGED_ATTACK,
	CHASE,
	RUN,
	HEAL
}

var passive_state: ENEMY_STATES_PASSIVE = ENEMY_STATES_PASSIVE.PATROL
var active_state: ENEMY_STATES_ACTIVE = ENEMY_STATES_ACTIVE.CHASE
var watch_timer := 0.0
var watch_duration := 0.0

var reacting := false
var react_move_dir := Vector3.ZERO
var react_timer := 0.0

func _ready():
	sprite.scale = Vector3(2, 2, 2)
	
	var hp_bar = $WorldUI/ResourceBars/HPSPBars/HPBarFG
	var sp_bar = $WorldUI/ResourceBars/HPSPBars/SPBarFG
	hp_bar.material_override = hp_bar.material_override.duplicate()
	sp_bar.material_override = sp_bar.material_override.duplicate()
	
	enemy_stats.hp = enemy_stats.max_hp
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
		
	hitbox.hit_received.connect(_on_hit_received)
	
	targeting_controller.targeting_started.connect(_on_targeting_started)
	targeting_controller.cast_started.connect(_on_skill_cast_started)
	targeting_controller.cast_completed.connect(_on_skill_cast_completed)
	targeting_controller.cast_cancelled.connect(_on_skill_cast_cancelled)
	targeting_controller.cast_interrupted.connect(_on_skill_cast_interrupted)
		
func _physics_process(delta: float) -> void:
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
	if IN_COMBAT:
		if enemy_stats.sp < enemy_stats.max_sp:
			enemy_stats.sp = min(enemy_stats.sp + enemy_stats.sp_regen_rate * delta, enemy_stats.max_sp)
	elif !IN_COMBAT:
		if enemy_stats.hp < enemy_stats.max_hp:
			enemy_stats.hp = min (enemy_stats.hp + enemy_stats.hp_regen_rate * delta, enemy_stats.max_hp)
	
	resource_bar_transition(delta)
	
func _process_passive_state(delta: float):
	var distance_to_player = horizontal_distance_to_player()
	var distance_to_spawn = horizontal_distance_to_spawn()
	
	if distance_to_player <= ENGAGE_RADIUS:
		enter_combat()
		return
		
	#if distance_to_player > PATROL_RADIUS:
		## Continue passive behavior
		#pass
		
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
				enter_watch(1.0)
			elif distance_to_player < INVESTIGATION_RADIUS:
				enter_watch(2.0)
				
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
				velocity.z = 0.0
				
				pick_new_patrol_point()
				passive_state = ENEMY_STATES_PASSIVE.PATROL

func _on_hit_received(instigator, skill, damage, target_data) -> void:
	enemy_stats.hp -= damage

func _process_active_state(delta: float):
	if reacting:
		_process_reaction(delta)
		return
	
	if movement_locked:
		velocity.x = 0.0
		velocity.z = 0.0
		
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	var distance_to_spawn = global_position.distance_to(spawn_position)
	
	match active_state:
		ENEMY_STATES_ACTIVE.CHASE:
			$WorldUI/Label3D.text = "Enemy on CHASE"
			chase_player(distance_to_player, RUN_SPEED)
			
			var skill := _get_first_available_ranged_skill()
			
			if skill == null:
				active_state = ENEMY_STATES_ACTIVE.CHASE
				return
			
			if distance_to_player < ATTACK_RANGE and attack_cooldown_timer <= 0.0:
				active_state = ENEMY_STATES_ACTIVE.ATTACK
				var dir = (player.global_position - global_position)
				dir.y = 0.0
				update_sprite(dir.normalized())
				
			elif distance_to_player <= skill.range_value and attack_cooldown_timer <= 0.0:
				active_state = ENEMY_STATES_ACTIVE.RANGED_ATTACK
			
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
				
				if is_instance_valid(player) and horizontal_distance_to_player() <= ATTACK_RANGE:
					player.player_stats.hp -= enemy_stats.atk
				
			if attack_timer >= attack_duration:
				attack_timer = 0.0
				attack_landed = false
				attack_cooldown_timer = attack_cooldown
				active_state = ENEMY_STATES_ACTIVE.CHASE
		
		ENEMY_STATES_ACTIVE.RANGED_ATTACK:
			$WorldUI/Label3D.text = "Enemy on RANGED ATTACK"
			velocity.x = 0.0
			velocity.z = 0.0
			update_sprite(Vector3.ZERO)
			
			if not ranged_attack_started:
				ranged_attack_started = true
				_start_ranged_skill()
						
			if targeting_controller.state != SkillTargetingController.State.IDLE:
				var skill := targeting_controller.active_skill
				if skill and distance_to_player > skill.range_value:
					targeting_controller.cancel()
				
		ENEMY_STATES_ACTIVE.HEAL:
			$WorldUI/Label3D.text = "Enemy on HEAL"
			active_heal()

func _process_reaction(delta: float) -> void:
	react_timer -= delta
	
	if react_timer <= 0.0:
		reacting = false
		
		if is_instance_valid(guard):
			guard.is_active = false
		return
		
	if movement_locked:
		velocity.x = 0.0
		velocity.z = 0.0
		
	else:
		velocity.x = react_move_dir.x * RUN_SPEED
		velocity.z = react_move_dir.z * RUN_SPEED
		
	update_sprite(react_move_dir)

func active_heal():
	active_state = ENEMY_STATES_ACTIVE.CHASE
	if enemy_stats.hp < 0.1 * enemy_stats.max_hp and randf() >= 0.3:
		enemy_stats.hp = min(enemy_stats.hp + 100.0, enemy_stats.max_hp)

func enter_watch(duration: float = wait_time, return_home: bool = false) -> void:
	passive_state = ENEMY_STATES_PASSIVE.WATCH
	
	watch_timer = 0.0
	watch_duration = duration
	returning_home = return_home
	
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
		print("Player entered Investigation Range")
		
	elif distance_to_spawn > PATROL_RADIUS:
		passive_state = ENEMY_STATES_PASSIVE.DISENGAGE
		print("Player exited Engage Range")
		
	elif distance_to_player < DETECTION_RADIUS:
		passive_state = ENEMY_STATES_PASSIVE.SLOW_PATROL
		print("Player entered Slow Patrol Range")
		
	else:
		pick_new_patrol_point()
		passive_state = ENEMY_STATES_PASSIVE.PATROL

func enter_combat():
	if IN_COMBAT:
		return
	
	IN_COMBAT = true
	resource_bar_visibility()
	$InteractionArea.visible = false
	
	CombatManager.enter_combat(self)
	active_state = ENEMY_STATES_ACTIVE.CHASE
	
func exit_combat():
	if !IN_COMBAT:
		return
		
	IN_COMBAT = false
	resource_bar_visibility()
	$InteractionArea.visible = true
	
	CombatManager.exit_combat(self)
	enter_watch(5.0, true)

func walk_routine(move_speed: float) -> bool:
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
	if distance > ATTACK_RANGE:
		var target_dir = (player.global_position - global_position).normalized()
		velocity.x = target_dir.x * move_speed
		velocity.z = target_dir.z * move_speed
		update_sprite(target_dir)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		update_sprite(Vector3.ZERO)

func _get_skill_animation(skill: SkillData) -> AnimType:
	if skill.cast_time >= 1.5:
		return AnimType.HEAVY
		
	elif skill.cast_time  >= 0.75:
		return AnimType.STRONG
		
	else:
		return AnimType.LIGHT
		
func _on_targeting_started(skill: SkillData) -> void:
	casting_state = true
	attack = false

	update_sprite(Vector3.ZERO)
	
	if horizontal_distance_to_player() > skill.range_value:
		_finish_ranged_attack()

func _on_skill_cast_started(skill: SkillData, target_data: Dictionary) -> void:
	casting_state = false
	attack = true
	movement_locked = true

	anim = _get_skill_animation(skill)

	update_sprite(Vector3.ZERO)

func _on_skill_cast_completed(skill: SkillData, target_data: Dictionary) -> void:
	_execute_skill(skill, target_data)

func _on_skill_cast_cancelled(skill: SkillData) -> void:
	movement_locked = false
	casting_state = false
	attack = false

	ranged_attack_started = false
	active_state = ENEMY_STATES_ACTIVE.CHASE

	update_sprite(Vector3.ZERO)

func _on_animation_finished() -> void:
	if not attack:
		return

	movement_locked = false
	casting_state = false
	attack = false

	ranged_attack_started = false
	attack_cooldown_timer = attack_cooldown
	active_state = ENEMY_STATES_ACTIVE.CHASE

	update_sprite(Vector3.ZERO)

func _dodge_projectile(threat: Dictionary) -> Vector3:
	var projectile: Projectile = threat.get("projectile")

	if not is_instance_valid(projectile):
		return Vector3.ZERO

	var direction := projectile.direction
	direction.y = 0.0
	direction = direction.normalized()

	var to_enemy := global_position - projectile.global_position
	to_enemy.y = 0.0

	# Perpendicular vector to projectile trajectory.
	var perpendicular := Vector3(
		-direction.z,
		0.0,
		direction.x
	)

	# Which side of the trajectory are we currently on?
	var side := to_enemy.dot(perpendicular)

	if side >= 0.0:
		return perpendicular.normalized()

	return -perpendicular.normalized()
	
func _dodge_shape(threat: Dictionary) -> Vector3:
	var target_data: Dictionary = threat.get("target_data", {})

	var center: Vector3

	if target_data.has("target_point"):
		center = target_data["target_point"]
	elif target_data.has("origin"):
		center = target_data["origin"]
	else:
		return Vector3.ZERO

	var away := global_position - center
	away.y = 0.0

	if away.is_zero_approx():
		# We're basically at the center.
		# Pick an arbitrary escape direction.
		return Vector3.FORWARD

	return away.normalized()

func _dodge_surehit(threat: Dictionary) -> Vector3:
	var target_data: Dictionary = threat.get("target_data", {})

	if not target_data.has("target_point"):
		return Vector3.ZERO

	var away: Vector3 = global_position - target_data["target_point"]
	away.y = 0.0

	if away.is_zero_approx():
		return Vector3.ZERO

	return away.normalized()

func get_dodge_direction(threat: Dictionary) -> Vector3:
	match threat.get("kind"):
		"projectile":
			return _dodge_projectile(threat)

		"shape":
			return _dodge_shape(threat)

		"surehit":
			return _dodge_surehit(threat)

	return Vector3.ZERO

func _on_skill_cast_interrupted(skill: SkillData, threat: Dictionary) -> void:
	reacting = true
	react_timer = REACTION_TIMER
	
	react_move_dir = get_dodge_direction(threat)
	
	if is_instance_valid(guard):
		guard.is_active = false

func _execute_skill(skill: SkillData, target_data: Dictionary = {}) -> void:
	enemy_stats.sp -= skill.sp_cost
	skill_use_timer = skill_use_cd
	
	print("EXECUTE TARGET DATA = ", target_data)
	print("Enemy used %s!" % skill.display_name)
		
	match skill.attack_type:
		SkillData.AttackType.SUREHIT:
			SkillCombat.resolve_surehit(skill, self, target_data)
			
		SkillData.AttackType.SKILLSHOT:
			SkillCombat.resolve_skillshot(skill, self, target_data)
			
		SkillData.AttackType.AOE:
			if skill.behavior is AOEBehavior and skill.behavior.shape == AOEBehavior.AOEShape.CONE:
				SkillCombat.resolve_aoe_cone(skill, self, target_data)
			else:
				SkillCombat.resolve_aoe_circle(skill, self, target_data)
		
	_finish_ranged_attack()

func _get_first_available_ranged_skill() -> SkillData:
	if enemy_skills == null:
		return null

	for skill_id in enemy_skills.equipped_active_skills:
		if skill_id.is_empty():
			continue

		var skill: SkillData = SkillDatabase.get_skill(skill_id)

		if skill == null:
			continue

		if skill.sp_cost > enemy_stats.sp:
			continue

		if skill.attack_type == SkillData.AttackType.SUREHIT:
			return skill

		if skill.attack_type == SkillData.AttackType.SKILLSHOT:
			return skill

		if skill.attack_type == SkillData.AttackType.AOE:
			return skill

	return null

func _start_ranged_skill() -> void:
	if not is_instance_valid(player):
		_finish_ranged_attack()
		return
		
	if enemy_skills == null:
		push_warning("%s has no EntitySkills resource" % name)
		_finish_ranged_attack()
		return
		
	if enemy_skills.equipped_active_skills.is_empty():
		push_warning("%s has no equipped active skills" % name)
		_finish_ranged_attack()
		return
		
	var skill_id: String = enemy_skills.equipped_active_skills[0]
	
	if skill_id.is_empty():
		_finish_ranged_attack()
		return
	
	var skill: SkillData = SkillDatabase.get_skill(skill_id)
	
	if skill == null:
		push_warning("Could not find skill: " + skill_id)
		_finish_ranged_attack()
	
	if skill.sp_cost > enemy_stats.sp:
		_finish_ranged_attack()
		return
	
	targeting_controller.start_ai_targeting(skill, player, 5.0, 2.0)

func _finish_ranged_attack() -> void:
	ranged_attack_started = false
	movement_locked = false
	casting_state = false
	attack = false
	active_state = ENEMY_STATES_ACTIVE.CHASE

func update_sprite(move_dir: Vector3):
	var horizontal_dir := Vector2(move_dir.x, move_dir.z)
	
	if horizontal_dir.x > 0.01:
		facing_right = true
	elif horizontal_dir.x < -0.01:
		facing_right = false
		
	sprite.flip_h = !facing_right
	
	if casting_state:
		if sprite.animation != "casting":
			sprite.play("casting")
		return
		
	if attack:
		var animation_name := ""
		
		match anim:
			AnimType.LIGHT:
				animation_name = "light_attack"
			AnimType.STRONG:
				animation_name = "strong_attack"
			AnimType.HEAVY:
				animation_name = "heavy_attack"

		if sprite.animation != animation_name:
			sprite.play(animation_name)

		return
			
	
	if horizontal_dir.length() > 0.01:
		if IN_COMBAT:
			sprite.play("walk_a")
		else:
			sprite.play("walk_p")
	else:
		sprite.play("idle")
		
	if active_state == ENEMY_STATES_ACTIVE.ATTACK:
		sprite.play("attack")
		
func resource_bar_transition(delta: float):
	var target_hp_pct = enemy_stats.hp / enemy_stats.max_hp
	var target_sp_pct = enemy_stats.sp / enemy_stats.max_sp
	
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
	$WorldUI/ResourceBars/HPSPBars.visible = IN_COMBAT or is_hovered

func update_hp_bar():
	($WorldUI/ResourceBars/HPSPBars/HPBarFG.material_override as ShaderMaterial).set_shader_parameter("fill_amount", displayed_hp_pct)

func update_sp_bar():
	($WorldUI/ResourceBars/HPSPBars/SPBarFG.material_override as ShaderMaterial).set_shader_parameter("fill_amount", displayed_sp_pct)

func update_cast_progress():
	($WorldUI/ResourceBars/CastingUI/CastProgressFG.material_override as ShaderMaterial).set_shader_parameter("fill_amount", displayed_cast_pct)

func start_progress_ui() -> void:
	print("Start progress was called by Enemy Targeting controller")
	enemy_stats.cast = 0.0
	displayed_cast_pct = 0.0
	update_cast_progress()
	
	casting_progress_ui.visible = true
	
func set_progress_ui(value: float) -> void:
	enemy_stats.cast = clamp(value, 0.0, enemy_stats.max_cast)
	displayed_cast_pct = enemy_stats.cast / enemy_stats.max_cast
	
	update_cast_progress()
	
func stop_progress_ui() -> void:
	casting_progress_ui.visible = false
	enemy_stats.cast = 0.0
