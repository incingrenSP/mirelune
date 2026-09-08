class_name SkillEntry
extends PanelContainer

signal entry_selected(skill_id: String)

@onready var skill_name_label: Label = $MarginContainer/EntryVBox/InfoHBox/SkillNameLabel
@onready var cost_label: Label = $MarginContainer/EntryVBox/InfoHBox/CostLabel
@onready var damage_label: Label = $MarginContainer/EntryVBox/InfoHBox/DamageLabel
@onready var description_box: Label = $MarginContainer/EntryVBox/Description
@onready var entry_vbox: VBoxContainer = $MarginContainer/EntryVBox

var skill_id: String = ""
			
func setup(skill_data: SkillData) -> void:
	skill_id = skill_data.id
	
	skill_name_label.text = skill_data.display_name
	cost_label.text = "SP: %d" % skill_data.sp_cost
	damage_label.text = "DMG: %s" % skill_data.damage_scaling
	description_box.text = skill_data.description
	
	description_box.autowrap_mode = TextServer.AUTOWRAP_WORD
	entry_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry_vbox.mouse_filter = Control.MOUSE_FILTER_STOP
		
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("I've been clicked D:")
			entry_selected.emit(skill_id)
