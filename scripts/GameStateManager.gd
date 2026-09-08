extends Node

enum GameMode {
	GAMEPLAY,
	DIALOG,
	PAUSED
}

var current_mode := GameMode.GAMEPLAY
var previous_mode := GameMode.GAMEPLAY

func is_gameplay_active() -> bool:
	return current_mode == GameMode.GAMEPLAY
	
func is_dialog_active() -> bool:
	return current_mode == GameMode.DIALOG
	
func is_paused() -> bool:
	return current_mode == GameMode.PAUSED
	
func enter_dialog() -> void:
	if current_mode != GameMode.GAMEPLAY:
		return
	
	current_mode = GameMode.DIALOG
	
func exit_dialog() -> void:
	if current_mode != GameMode.DIALOG:
		return
		
	current_mode = GameMode.GAMEPLAY

func can_pause() -> bool:
	if CombatManager.is_in_combat():
		return false
		
	return current_mode == GameMode.GAMEPLAY or current_mode == GameMode.DIALOG

func pause_game() -> void:
	if not can_pause():
		return
		
	previous_mode = current_mode
	current_mode = GameMode.PAUSED
	
	get_tree().paused = true
	
func resume_game() -> void:
	if current_mode != GameMode.PAUSED:
		return
		
	get_tree().paused = false
	current_mode = previous_mode
				
