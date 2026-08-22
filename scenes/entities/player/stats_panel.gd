extends Control

@onready var title_label: Label = $Title

@onready var name_label: Label = $PlayerInfo/PlayerName/NameLabel
@onready var level_label: Label = $PlayerInfo/PlayerName/LevelLabel
@onready var xp_bar: ProgressBar = $PlayerInfo/XPBar

@onready var hp_bar: ProgressBar = $ResourceBars/HPRow/HPBar
@onready var sp_bar: ProgressBar = $ResourceBars/SPRow/SPBar

#@onready var atk_label: Label = $StatsGrid/MinorStats/ATK/ATKLabel
#@onready var def_label: Label = $StatsGrid/MinorStats/DEF/DEFLabel
#@onready var spd_label: Label = $StatsGrid/MinorStats/SPD/SPDLabel

@onready var atk_value: Label = $StatsGrid/MinorStats/ATK/ATKValue
@onready var def_value: Label = $StatsGrid/MinorStats/DEF/DEFValue
@onready var spd_value: Label = $StatsGrid/MinorStats/SPD/SPDValue

#@onready var hp_regen_label: Label = $StatsGrid/MajorStats/HPRegen/HPRegenLabel
#@onready var sp_regen_label: Label = $StatsGrid/MajorStats/SPRegen/SPRegenLabel
#@onready var skill_slots_label: Label = $StatsGrid/MajorStats/SkillSlots/SkillSlotsLabel

@onready var hp_regen_value: Label = $StatsGrid/MajorStats/HPRegen/HPRegenValue
@onready var sp_regen_value: Label = $StatsGrid/MajorStats/SPRegen/SPRegenValue
@onready var skill_slots_value: Label = $StatsGrid/MajorStats/SkillSlots/SkillSlotsValue

func update_stats(player: Player) -> void:
	title_label.add_theme_font_size_override("title_font_size", 48)
	
	name_label.text = "%s :" % player.player_name
	level_label.text = "Lvl. %d" % player.player_level
	
	xp_bar.max_value = player.max_xp
	xp_bar.value = player.xp
	
	hp_bar.max_value = player.max_hp
	hp_bar.value = player.hp
	hp_bar.get_node("HPValue").text = "%d / %d" % [player.hp, player.max_hp]
	
	sp_bar.max_value = player.max_sp
	sp_bar.value = player.sp
	sp_bar.get_node("SPValue").text = "%d / %d" % [player.sp, player.max_sp]
	
	atk_value.text = "%d" % player.atk
	def_value.text = "%d" % player.def
	spd_value.text = "%d" % player.WALK_SPEED
	
	hp_regen_value.text = "%d/s" % player.hp_regen_rate
	sp_regen_value.text = "%d/s" % player.sp_regen_rate
	skill_slots_value.text = "%d" % player.skill_slots
	
