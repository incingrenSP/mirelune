extends Control

@onready var skill_wheel: SkillWheel = $SkillWheelContainer/SkillWheel
@onready var skill_inventory: Control = $SkillInventory

var player: Player
var pending_type_index: int = -1
var pending_slot_type := SkillData.SkillCategory.ACTIVE

func open(p: Player):
	player = p
	
	pending_type_index = -1
	pending_slot_type = SkillData.SkillCategory.ACTIVE
	
	skill_wheel.update_wheel(player)
	_hide_inventory()
	
func _ready():
	skill_inventory.visible = false
	
	skill_wheel.slot_selected.connect(_on_slot_selected)
	skill_wheel.core_selected.connect(_on_core_selected)
	skill_inventory.skill_chosen.connect(_on_skill_chosen)
	
func _on_slot_selected(slot: SkillWheelSlot):
	pending_type_index = slot.type_index
	pending_slot_type = slot.slot_type
	
	skill_inventory.open_for(pending_slot_type, player)
	_show_inventory()
	
func _on_core_selected():	
	pending_slot_type = SkillData.SkillCategory.CORE
	skill_inventory.open_for(SkillData.SkillCategory.CORE, player)
	_show_inventory()
	
func _on_skill_chosen(skill_id: String):
	if pending_slot_type == SkillData.SkillCategory.CORE:
		player.equip_core_skill(skill_id)
		
	else:
		player.equip_skill(pending_type_index, pending_slot_type, skill_id)
		
	skill_wheel.update_wheel(player)
	_hide_inventory()
	
func _show_inventory() -> void:
	skill_inventory.show()
	
func _hide_inventory() -> void:
	skill_inventory.hide()
