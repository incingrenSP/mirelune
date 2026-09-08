class_name SkillWheel
extends Control

enum Mode {
	PAUSE_MENU,
	COMBAT
}

signal slot_selected(slot: SkillWheelSlot)
signal slot_hovered(slot: SkillWheelSlot)
signal slot_unhovered(slot: SkillWheelSlot)
signal core_selected
signal core_hovered(is_hovered: bool)
signal core_unhovered

@export var mode: Mode = Mode.PAUSE_MENU
@export var core_radius := 40.0;
@export var outer_radius := 150.0;
@export var slot_gap := 4.0

var slots: Array[SkillWheelSlot] = []

@onready var core: SkillWheelCore = $Core
@onready var wedges: Control = $Wedges
@onready var interaction_layer: SkillWheelInteraction = $InteractionLayer
@onready var cooldown_overlay: SkillCooldownOverlay = $CooldownOverlay
@onready var cooldown_label: Label = $CooldownLabel

func _ready() -> void:
	interaction_layer.setup(self)
	core.core_radius = core_radius
	
	cooldown_overlay.radius = outer_radius
	cooldown_overlay.set_progress(1.0)
	
	for child in wedges.get_children():
		if child is SkillWheelSlot:
			slots.append(child)
			child.selected.connect(_on_slot_selected)
			child.hovered.connect(_on_slot_hovered)
			child.unhovered.connect(_on_slot_unhovered)
			
	core.core_selected.connect(_on_core_selected)
	core.core_hovered.connect(_on_core_hovered)
	core.core_unhovered.connect(_on_core_unhovered)
	
	_configure_layout()
	
func _configure_layout() -> void:
	var slice_angle: float = TAU / slots.size()
	var gap_rad: float = deg_to_rad(slot_gap)
	
	for i in slots.size():
		var slot: SkillWheelSlot = slots[i]
		var half_slice: float = slice_angle / 2.0
		
		var start_angle: float = i * slice_angle - half_slice - PI / 2.0 + gap_rad
		var end_angle: float = i * slice_angle + half_slice - PI / 2.0 - gap_rad
		
		slot.inner_radius = core_radius
		slot.outer_radius = outer_radius
		
		slot.start_angle = start_angle
		slot.end_angle = end_angle
		
		slot.type_index = i / 2
		
		if i % 2 == 0:
			slot.slot_type = SkillData.SkillCategory.ACTIVE
			
		else:
			slot.slot_type = SkillData.SkillCategory.PASSIVE
		
func _on_slot_selected(slot: SkillWheelSlot) -> void:
	slot_selected.emit(slot)
	
func _on_slot_hovered(slot: SkillWheelSlot) -> void:
	slot_hovered.emit(slot)
	
func _on_slot_unhovered(slot: SkillWheelSlot) -> void:
	slot_unhovered.emit(slot)
	
func _on_core_selected() -> void:
	core_selected.emit()
	
func _on_core_hovered() -> void:
	core_hovered.emit()
	
func _on_core_unhovered() -> void:
	core_unhovered.emit()

func update_wheel(player: Player) -> void:
	print("========== UPDATE WHEEL ==========")
	print("Player: ", player)
	print("core_unlocked: ", player.player_skills.core_unlocked)
	print("core_skill_id: ", player.player_skills.core_skill_id)
	print("active slots: ", player.player_skills.unlocked_active_slots)
	print("passive slots: ", player.player_skills.unlocked_passive_slots)
	print("active skills: ", player.player_skills.equipped_active_skills)
	print("passive skills: ", player.player_skills.equipped_passive_skills)
	
	for slot in slots:
		
		var skill_id: String = ""
		var unlocked: bool = false
		
		if slot.slot_type == SkillData.SkillCategory.ACTIVE:
			unlocked = slot.type_index < player.player_skills.unlocked_active_slots
			skill_id = player.player_skills.equipped_active_skills[slot.type_index]
			
		else:
			unlocked = slot.type_index < player.player_skills.unlocked_passive_slots
			skill_id = player.player_skills.equipped_passive_skills[slot.type_index]
			
		var skill_data = SkillDatabase.get_skill(skill_id)
		slot.setup(
			slot.type_index,
			slot.slot_type,
			skill_data,
			unlocked,
			slot.start_angle,
			slot.end_angle
		)
		
		print(
			"Slot | type=", slot.slot_type,
			" index=", slot.type_index,
			" skill=", slot.skill_data
		)
		
	var core_skill = SkillDatabase.get_skill(player.player_skills.core_skill_id) if player.player_skills.core_skill_id != "" else null
		
	core.setup(core_skill, player.player_skills.core_unlocked)
	
	print(
		"CORE | unlocked=", player.player_skills.core_unlocked,
		" skill_id=", player.player_skills.core_skill_id,
		" data=", core_skill
	)
	
func set_mode(new_mode: Mode) -> void:
	mode = new_mode
		
	for slot in slots:
		if mode == Mode.COMBAT:
			var is_active: bool = (
				slot.slot_type == SkillData.SkillCategory.ACTIVE and 
				slot.state == SkillWheelSlot.State.EQUIPPED
				)
			
			print(
				" slot=",
				slot.get_path(),
				" type=",
				slot.slot_type,
				" state=",
				slot.state,
				" active=",
				is_active
			)
			
			slot.set_interactable(is_active)
		else:
			slot.set_interactable(true)
			
	core.set_interactable(mode != Mode.COMBAT)
	
func set_cooldown_progress(progress: float) -> void:
	cooldown_overlay.set_progress(progress)
	cooldown_label.visible = (progress != 1.0)
	cooldown_label.text = "%.1f" % [(1.0 - progress) * CombatSkillOverlay.SWITCH_COOLDOWN_SEC]
		
