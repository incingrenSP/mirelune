class_name Player
extends Entity

const WALK_SPEED = 4.0
const RUN_SPEED = 10.0
const GRAVITY = 18.0
const INTERACT_TIMEOUT := 0.5

var facing_right := true
var interact_timer := 0.0

@onready var sprite: AnimatedSprite3D = $Visual/AnimatedSprite3D
@onready var player_targeting: Node = $PlayerSkillInput
@onready var skill_targeting: SkillTargetingController = $SkillTargetingController

@export var pause_menu: PauseMenu
@export var skill_wheel_overlay: CombatSkillOverlay
@export var trigger_area: PlayerTriggerArea
@export var IN_COMBAT := false
@export var camera : Node3D

var is_hovered := false
var input_locked := false

@export var player_portrait: Texture2D = null
@export var player_stats: PlayerStats
@export var player_skills: PlayerSkillInfo

var skill_use_cd: float = 0.5
var skill_use_timer: float = 0.0

signal skills_changed

func _ready():
	print("===PLAYER.gd READY===")
	player_stats.hp = player_stats.max_hp
	
	player_skills.player_unlocked_skills.append("0")
	print("SkillID = 0 in Database: ", SkillDatabase.get_skill("0"))
	print("Active Skill Slots: %d" % player_skills.unlocked_active_slots)
	print("Passive Skill Slots: %d" % player_skills.unlocked_passive_slots)

	var cam = get_tree().get_first_node_in_group("camera")
	if cam:
		cam.set_default_target(focus_point)
		player_targeting.camera = cam
		
	DialogManager.dialog_finished.connect(_on_dialog_finished)
	
	skill_targeting.cast_completed.connect(_on_skill_targeting_completed)

func _physics_process(delta: float) -> void:
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
	
func _process(delta: float) -> void:
	if IN_COMBAT:
		if player_stats.hp < player_stats.max_hp:
			player_stats.hp = min(player_stats.hp + player_stats.hp_regen_rate * delta, player_stats.max_hp)
			
		if player_stats.sp < player_stats.max_sp:
			player_stats.sp = min(player_stats.sp + player_stats.sp_regen_rate * delta, player_stats.max_sp)
						
	if interact_timer > 0.0:
		interact_timer -= delta
	
	if skill_use_timer > 0.0:
		skill_use_timer -= delta
		
	resource_bar_transition(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_G:
				player_stats.xp = min(
					player_stats.xp + 10,
					player_stats.max_xp
				)

			KEY_1:
				player_skills.unlocked_active_slots = min(
					player_skills.unlocked_active_slots + 1,
					player_skills.MAX_ACTIVE_SLOTS
				)

			KEY_2:
				player_skills.unlocked_passive_slots = min(
					player_skills.unlocked_passive_slots + 1,
					player_skills.MAX_PASSIVE_SLOTS
				)
				
			KEY_F:
				use_skill(player_skills.current_skill)

func _execute_skill(skill: SkillData, target_data: Dictionary = {}) -> void:
	player_stats.sp -= skill.sp_cost
	skill_use_timer = skill_use_cd
	
	print("Player used %s!" % skill.display_name)
	
	# Combat system / skill behavior goes here

func _on_skill_targeting_completed(skill: SkillData, target_data: Dictionary) -> void:
	_execute_skill(skill, target_data)

func _on_dialog_finished() -> void:
	interact_timer = INTERACT_TIMEOUT

func try_to_interact(target: Interactable) -> void:
	print("========================================")
	print("PLAYER TRY TO INTERACT")

	if interact_timer > 0.0:
		print(">>>> PLAYER INTERACT ON TIMEOUT")
		return
		
	if target == null:
		return

	if GameStateManager.is_dialog_active():
		return

	if target not in trigger_area.nearby_interactables:
		print(">>> TARGET IS NOT IN PLAYER RANGE")
		return

	print(">>> TARGET IS IN PLAYER RANGE")
	target.interact()

func update_sprite(input_dir: Vector2):
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
		
		
func resource_bar_transition(delta: float):
	var target_hp_pct = player_stats.hp / player_stats.max_hp
	var target_sp_pct = player_stats.sp / player_stats.max_sp
	
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
	
func set_combat_state(value: bool):
	IN_COMBAT = value
	
	show_skill_wheel()
	resource_bar_visibility()
	
func is_slot_unlocked(slot_type: SkillData.SkillCategory, slot_index: int) -> bool:
	match slot_type:
		SkillData.SkillCategory.ACTIVE:
			return slot_index < player_skills.unlocked_active_slots
		
		SkillData.SkillCategory.PASSIVE:
			return slot_index < player_skills.unlocked_passive_slots
			
		SkillData.SkillCategory.CORE:
			return player_skills.core_unlocked
			
	return false

func equip_skill(slot_index: int, slot_type: SkillData.SkillCategory, skill_id: String):
	if not is_slot_unlocked(slot_type, slot_index):
		return
		
	var target_array: Array[String]
	
	match slot_type:
		SkillData.SkillCategory.ACTIVE:
			target_array = player_skills.equipped_active_skills
			
		SkillData.SkillCategory.PASSIVE:
			target_array = player_skills.equipped_passive_skills
			
		SkillData.SkillCategory.CORE:
			return
			
	var existing_index := target_array.find(skill_id)
	if existing_index != -1 and existing_index != slot_index:
		target_array[existing_index] = ""
		
	target_array[slot_index] = skill_id
	
	skills_changed.emit()
	
func equip_core_skill(skill_id: String):
	if not player_skills.core_unlocked:
		return
		
	player_skills.core_skill_id = skill_id
	skills_changed.emit()
	
func use_skill(skill_id: String) -> void:
	var data: SkillData = SkillDatabase.get_skill(skill_id)
	
	if data == null:
		print("Player has no skill registered")
		return
	
	if player_stats.sp < data.sp_cost:
		print("SP too low | Cost: %d  Player SP: %d" % [
			data.sp_cost,
			player_stats.sp
		])
		return
	
	if skill_use_timer > 0.0:
		print("Skill use on cooldown: %.1f" % skill_use_timer)
		return
	
	match data.attack_type:
		SkillData.AttackType.SKILLSHOT, \
		SkillData.AttackType.SUREHIT, \
		SkillData.AttackType.AOE:
			skill_targeting.start_targeting(data)
			
		_:
			_execute_skill(data)

func resource_bar_visibility():
	$WorldUI/Label3D.visible = IN_COMBAT or is_hovered
	$WorldUI/ResourceBars.visible = IN_COMBAT or is_hovered

func show_skill_wheel() -> void:
	if IN_COMBAT:
		skill_wheel_overlay.open(self)
		return
		
	skill_wheel_overlay.close()

func update_hp_bar():
	($WorldUI/ResourceBars/HPBarFG.material_override as ShaderMaterial).set_shader_parameter("fill_amount", displayed_hp_pct)

func update_sp_bar():
	($WorldUI/ResourceBars/SPBarFG.material_override as ShaderMaterial).set_shader_parameter("fill_amount", displayed_sp_pct)

func request_pause():
	pause_menu.open()
