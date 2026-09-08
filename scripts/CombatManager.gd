extends Node

var combatants: Array[Enemy] = []

signal combat_started
signal combat_ended
signal combatant_added(enemy: Enemy)
signal combatant_removed(enemy: Enemy)

func enter_combat(enemy: Enemy) -> void:
	if enemy == null:
		return
		
	if enemy in combatants:
		return
	
	var was_in_combat := not combatants.is_empty()
	combatants.append(enemy)
	combatant_added.emit(enemy)
	
	if !was_in_combat:
		combat_started.emit()
	
	_update_combat_state()
	
func exit_combat(enemy: Enemy):
	if enemy == null:
		return
		
	if enemy not in combatants:
		return
		
	combatants.erase(enemy)
	combatant_removed.emit(enemy)
	
	if combatants.is_empty():
		combat_ended.emit()
		
	_update_combat_state()
	
func is_in_combat() -> bool:
	_cleanup_combatants()
	return not combatants.is_empty()
	
func get_combatants() -> Array[Enemy]:
	_cleanup_combatants()
	return combatants
	
func _cleanup_combatants() -> void:
	for enemy in combatants.duplicate():
		if !is_instance_valid(enemy):
			combatants.erase(enemy)

func _update_combat_state():
	var player := get_tree().get_first_node_in_group("player") as Player
	
	if player == null:
		return
		
	player.set_combat_state(not combatants.is_empty())
	
