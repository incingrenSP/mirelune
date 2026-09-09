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
			
