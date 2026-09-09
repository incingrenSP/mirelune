class_name CombatSkillOverlay
extends Control

@onready var skill_wheel: SkillWheel = $SkillWheel

var player: Player
var registered_skill_id: String = ""

const SWITCH_COOLDOWN_SEC: float = 10.0
var cooldown_timer: float = 0

func _ready() -> void:
	visible = false
		
	skill_wheel.slot_selected.connect(_on_slot_selected)
	
	CombatManager.combat_started.connect(_on_combat_started)
	CombatManager.combat_ended.connect(_on_combat_ended)
	
func _process(delta: float) -> void:
	if not visible:
		return
	
	if is_on_cooldown():
		cooldown_timer -= delta
		var progress: float = 1.0 - (cooldown_timer / SWITCH_COOLDOWN_SEC)
		skill_wheel.set_cooldown_progress(progress)
		
	else:
		skill_wheel.set_cooldown_progress(1.0)
	
func _position_beside_player() ->  Vector2:
	var cam := get_viewport().get_camera_3d()
	if cam == null or player == null:
		return Vector2.ZERO
		
	var screen_pos: Vector2 = cam.unproject_position(player.global_position)
	return screen_pos + Vector2(200, -150)
			
func _on_slot_selected(slot: SkillWheelSlot) -> void:
	print("Slot was selected")
	if slot.skill_data == null:
		print("Skill data found null, returned")
		return
		
	if slot.skill_data.category != SkillData.SkillCategory.ACTIVE:
		print("Skill slot category found not ACTIVE")
		return
	
	if is_on_cooldown():
		print("Skill switch on cooldown: %.1f" % cooldown_timer)
		return
		
	if slot.skill_data.id == registered_skill_id:
		print("Selected skill is already registered")
		return
		
	print("Skill registered")
	registered_skill_id = slot.skill_data.id
	player.player_skills.current_skill = registered_skill_id
	cooldown_timer = SWITCH_COOLDOWN_SEC
	
func _on_combat_started() -> void:
	skill_wheel.set_mode(SkillWheel.Mode.COMBAT)
	
func _on_combat_ended() -> void:
	skill_wheel.set_mode(SkillWheel.Mode.PAUSE_MENU)
	
func is_on_cooldown() -> bool:
	if cooldown_timer > 0.0:
		return true
	return false
	
func open(p: Player) -> void:
	player = p
	
	skill_wheel.update_wheel(player)
	skill_wheel.set_mode(SkillWheel.Mode.COMBAT)
	#global_position = _position_beside_player()
	
	visible = true
	#Engine.time_scale = 0.25
	
func close() -> void:	
	visible = false
	#Engine.time_scale = 1.0
