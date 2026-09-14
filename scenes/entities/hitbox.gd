class_name Hitbox
extends Area3D

signal hit_received(instigator: Node3D, skill: SkillData, damage: float, target_data: Dictionary)
signal hit_blocked(instigator: Node3D, skill: SkillData, target_data: Dictionary)

@export var faction: String = "neutral"
@export var stat_component: StatComponent
@export var guard: Guard

func _ready() -> void:
	if stat_component == null:
		var parent := get_parent()
		
		if is_instance_valid(parent):
			stat_component = parent.get_node_or_null("StatComponent") as StatComponent
			
	HitboxRegistry.register(self)
	
	mouse_entered.connect(_on_mouse_entered)
	
func _on_mouse_entered() -> void:
	var parent := get_parent()
	print("%s hitbox hovered | Hitbox : %s" % [parent, self])
	
func _exit_tree() -> void:
	HitboxRegistry.unregister(self)
	
func receive_hit(instigator: Node3D, skill: SkillData, target_data: Dictionary = {}) -> float:
	if not skill.indiscriminate and is_instance_valid(instigator):
		var instigator_hitbox := instigator.get_node_or_null("Hitbox") as Hitbox
		
		if is_instance_valid(instigator_hitbox) and instigator_hitbox.faction == faction:
			return 0.0
			
	var hit_direction := skill.compute_hit_direction(instigator, target_data)
	
	if is_instance_valid(guard) and guard.blocks(hit_direction):
		hit_blocked.emit(instigator, skill, target_data)
		return 0.0
	
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
