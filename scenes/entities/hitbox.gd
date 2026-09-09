class_name Hitbox
extends Area3D

signal hit_received(instigator: Node3D, skill: SkillData, damage: float, target_data: Dictionary)

@export var faction: String = "neutral"
@export var stat_component: StatComponent

func _ready() -> void:
	if stat_component == null:
		var parent := get_parent()
		
		if is_instance_valid(parent):
			stat_component = parent.get_node_or_null("StatComponent") as StatComponent
			
	HitboxRegistry.register(self)
	
func _exit_tree() -> void:
	HitboxRegistry.unregister(self)
	
func receive_hit(instigator: Node3D, skill: SkillData, target_data: Dictionary = {}) -> float:
	var instigator_stats := {}
	var my_stats := {}
	
	if is_instance_valid(instigator):
		var instigator_stat_component := instigator.get_node_or_null("StatComponent") as StatComponent
		
		if is_instance_valid(instigator_stat_component):
			instigator_stats = instigator_stat_component.get_stats_as_formula_dict()
	
	if is_instance_valid(stat_component):
		my_stats = stat_component.get_stats_as_formula_dict()
	
	var damage := skill.calculate_damage(instigator_stats, my_stats)
	hit_received.emit(instigator, skill, damage, target_data)
	
	return damage
