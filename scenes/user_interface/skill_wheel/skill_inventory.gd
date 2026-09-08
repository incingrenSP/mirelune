class_name SkillInventory
extends Control

signal skill_chosen(skill_id: String)


@onready var skill_menu_label: Label = $SkillMenuLabel
@onready var close_button: Button = $CloseButton
@onready var inventory_container: Control = $InventoryContainer
@onready var inventory: VBoxContainer = $InventoryContainer/ScrollContainer/VBoxContainer

const SKILL_ENTRY_SCENE := preload("res://scenes/user_interface/skill_wheel/skill_entry.tscn")

const CATEGORY_BY_SLOT_TYPE := {
	SkillData.SkillCategory.ACTIVE : "active",
	SkillData.SkillCategory.PASSIVE : "passive",
	SkillData.SkillCategory.CORE : "core",
}

func open_for(slot_type: SkillData.SkillCategory, player: Player) -> void:
	inventory_container.visible = true
	skill_menu_label.text = "%s SKILLS" % (CATEGORY_BY_SLOT_TYPE[slot_type]).to_upper()
	fetch_data(slot_type, player)
	
func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)
	
func _on_close_button_pressed():
	skill_menu_label.text = "SKILLS"
	inventory_container.visible = false
	hide()
	
func _clear_inventory():
	for child in inventory.get_children():
		child.queue_free()

func fetch_data(slot_type: SkillData.SkillCategory, player: Player):
	_clear_inventory()
	
	if not CATEGORY_BY_SLOT_TYPE.has(slot_type):
		push_error("SkillInventory: unknown slot type '%s'" % slot_type)
		return
		
	var wanted_category: SkillData.SkillCategory = slot_type
	
	for skill_id in player.player_skills.player_unlocked_skills:
		var data: SkillData = SkillDatabase.get_skill(skill_id)
		
		if data == null:
			push_warning("SkillInventory: no SkillData found for id '%s'" % skill_id)
			continue
		
		if data.category != wanted_category:
			continue
			
		var entry: SkillEntry = SKILL_ENTRY_SCENE.instantiate()
		inventory.add_child(entry)
		
		entry.setup(data)
		entry.mouse_filter = Control.MOUSE_FILTER_STOP
		entry.entry_selected.connect(_on_entry_selected)

func _on_entry_selected(skill_id: String) -> void:
	skill_chosen.emit(skill_id)
