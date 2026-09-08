class_name PauseMenu
extends Control

signal pause_opened
signal pause_closed

@onready var resume_button: Button = $Navigation/ButtonContainer/MenuButtons/Resume
@onready var save_button: Button = $Navigation/ButtonContainer/MenuButtons/Save
@onready var quit_button: Button = $Navigation/ButtonContainer/MenuButtons/Quit

@onready var content: Control = $Content
@onready var main_stats_panel: Control = $Content/PlayerStats/MainStatContainer/MainStatsPanel
@onready var player_stats_panel: Control = $Content/PlayerStats/StatsSkills/PlayerStatContainer/PlayerStatsPanel
@onready var skills_viewer: Control = $Content/PlayerStats/StatsSkills/SkillWheelContainer/SkillsViewer

@export var player: Player

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
func open() -> void:
	if not GameStateManager.can_pause():
		return
		
	GameStateManager.pause_game()
	pause_opened.emit()
	visible = true
	
	main_stats_panel.update_stats(player)
	player_stats_panel.update_stats(player)
	skills_viewer.open(player)
	
func close() -> void:
	if not GameStateManager.is_paused():
		return
		
	GameStateManager.resume_game()
	pause_closed.emit()
	visible = false

func _on_resume_pressed() -> void:
	close()

func _on_save_pressed() -> void:
	pass
	
func _on_quit_pressed() -> void:
	get_tree().quit()

func show_panel(panel: Control) -> void:
	for child in content.get_children():
		child.visible = false
		
	panel.visible = true
	
