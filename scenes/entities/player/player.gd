class_name Player
extends Entity

const WALK_SPEED = 4.0
const RUN_SPEED = 10.0
const GRAVITY = 18.0
const INTERACT_TIMEOUT := 0.5

var facing_right := true
var interact_timer := 0.0

@onready var sprite: AnimatedSprite3D = $Visual/AnimatedSprite3D

@export var pause_menu: PauseMenu
@export var skill_wheel_overlay: CombatSkillOverlay
@export var trigger_area: PlayerTriggerArea
@export var camera : Node3D
@export var IN_COMBAT := false

var is_hovered := false
var input_locked := false


@export var player_name: String = "Player"
@export var player_level: int = 1
@export var xp: int = 0
@export var max_xp: int = 100

@export var sp: float = 0.0
@export var max_sp: float = 100.0

@export var atk: int = 10
@export var def: int = 5
@export var spd: int = 4

@export var hp_regen_rate: float = 0.0
@export var sp_regen_rate: float = 5

const MAX_ACTIVE_SLOTS := 3
const MAX_PASSIVE_SLOTS := 3

@export var unlocked_active_slots: int = 3
@export var unlocked_passive_slots: int = 3

@export var equipped_active_skills: Array[String] = ["", "", ""]
@export var equipped_passive_skills: Array[String] = ["", "", ""]
@export var core_skill_id: String = ""

var player_unlocked_skills: Array[String] = []

signal skills_changed

func _ready():
	print("===PLAYER.gd READY===")
	
	player_unlocked_skills.append("0")

	hp = max_hp
	var cam = get_tree().get_first_node_in_group("camera")
	if cam:
		cam.set_default_target(focus_point)
		
	DialogManager.dialog_finished.connect(_on_dialog_finished)

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
	
func _process(delta: float) -> void:
	'''
	check if in combat
	if in combat -> sp regen
	permanent hp/sp bar visible
	update hp/sp bars
	'''
	if IN_COMBAT:
		if hp < max_hp:
			hp = min(hp + hp_regen_rate * delta, max_hp)
			
		if sp < max_sp:
			sp = min(sp + sp_regen_rate * delta, max_sp)
			
	if interact_timer > 0.0:
		interact_timer -= delta
		
	resource_bar_transition(delta)

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_G):
		xp = min(xp + 10, max_xp)

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

func _on_dialog_finished() -> void:
	interact_timer = INTERACT_TIMEOUT

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
		
		
func resource_bar_transition(delta: float):
	'''
	smooth transition for hp/sp bars
	'''
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
	
func set_combat_state(value: bool):
	IN_COMBAT = value
	
	resource_bar_visibility()
	
func is_slot_unlocked(slot_type: String, slot_index: int) -> bool:
	match slot_type:
		"active":
			return slot_index < unlocked_active_slots
		
		"passive":
			return slot_index < unlocked_passive_slots
	return false

func equip_skill(slot_index: int, slot_type: String, skill_id: String):
	if not is_slot_unlocked(slot_type, slot_index):
		return
		
	var target_array : Array[String] = equipped_active_skills if slot_type == "active" else equipped_passive_skills
	var existing_index := target_array.find(skill_id)
	if existing_index != -1 and existing_index != slot_index:
		target_array[existing_index] = ""
		
	target_array[slot_index] = skill_id
	skills_changed.emit()
	
func equip_core_skill(skill_id: String):
	core_skill_id = skill_id
	skills_changed.emit()
	
func use_skill(skill_id: String) -> void:
	var data: SkillData = SkillDatabase.get_skill(skill_id)
	if data == null:
		return
		
	if sp < data.sp_cost:
		return
		
	sp -= data.sp_cost

func show_skill_wheel():
	if not IN_COMBAT:
		return
	
	skill_wheel_overlay.open(self)

func resource_bar_visibility():
	'''
	resource bar toggle
	'''
	$WorldUI/Label3D.visible = IN_COMBAT or is_hovered
	$WorldUI/ResourceBars.visible = IN_COMBAT or is_hovered

func update_hp_bar():
	'''
	hp transition
	'''
	($WorldUI/ResourceBars/HPBarFG.material_override as ShaderMaterial).set_shader_parameter("fill_amount", displayed_hp_pct)

func update_sp_bar():
	'''
	sp transition
	'''
	($WorldUI/ResourceBars/SPBarFG.material_override as ShaderMaterial).set_shader_parameter("fill_amount", displayed_sp_pct)

func request_pause():
	pause_menu.open()
