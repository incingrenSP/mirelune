class_name AOEBehavior
extends SkillBehaviorData

enum AOEShape {
	CIRCLE,
	CONE,
	SUREHIT_ZONE
}

@export var shape: AOEShape
@export var multi_hit: int = 1
@export var blocked_by_terrain: bool = true
@export var accuracy: float = 1.0
