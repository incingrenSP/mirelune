extends Node3D

@onready var player: Player = $Player
@onready var pause_menu: PauseMenu = $GameUI/PauseMenu
@onready var skill_wheel_overlay: CombatSkillOverlay = $GameUI/CombatSkillOverlay

func _ready() -> void:
	player.pause_menu = pause_menu
	player.skill_wheel_overlay = skill_wheel_overlay
	
func _process(delta: float) -> void:
	pass
