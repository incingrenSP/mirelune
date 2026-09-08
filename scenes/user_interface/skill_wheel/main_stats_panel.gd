extends Control

@onready var player_portrait: TextureRect = $StatsPanel/Portrait
@onready var hp_bar: ProgressBar = $StatsPanel/PlayerStats/HPContainer/HPBar

@onready var sp_bar: ProgressBar = $StatsPanel/PlayerStats/SPContainer/SPBar

@onready var xp_bar: ProgressBar = $StatsPanel/PlayerStats/XPContainer/XPBar

@onready var player_name: Label = $NamePanel/PlayerID/PlayerName
@onready var player_level: Label = $NamePanel/PlayerID/PlayerLevel

func update_stats(player: Player) -> void:
	player_name.text = "%s" % player.player_stats.player_name
	player_level.text = "Lvl. %s" % player.player_stats.player_level
	
	player_portrait.texture = player.player_portrait
	
	hp_bar.max_value = player.player_stats.max_hp
	hp_bar.value = player.player_stats.hp

	sp_bar.max_value = player.player_stats.max_sp
	sp_bar.value = player.player_stats.sp
	
	xp_bar.max_value = player.player_stats.max_xp
	xp_bar.value = player.player_stats.xp
