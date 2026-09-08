extends Control

@onready var atk_label: Label = $MinorStats/ATKPanel/ATKValue
@onready var def_label: Label = $MinorStats/DEFPanel/DEFValue
@onready var adr_label: Label = $MinorStats/ADRPanel/ADRValue

@onready var hp_rate_label: Label = $MajorStats/HPRate/HPRateValue
@onready var sp_rate_label: Label = $MajorStats/SPRate/SPRateValue
@onready var spd_label: Label = $MajorStats/SPDPanel/SPDValue

func update_stats(player: Player) -> void:
	atk_label.text = "ATK: %d" % player.player_stats.atk
	def_label.text = "DEF: %d" % player.player_stats.def
	adr_label.text = "ADR: %d" % player.player_stats.adr
	
	hp_rate_label.text = "+HP: %d /s" % player.player_stats.hp_regen_rate
	sp_rate_label.text = "+SP: %d /s" % player.player_stats.sp_regen_rate
	spd_label.text = "SPD: %d" % player.player_stats.spd
