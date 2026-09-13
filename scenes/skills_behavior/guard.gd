class_name Guard
extends Node

enum Axis {
	HORIZONTAL,
	VERTICAL,
	ALL
}

@export var axis: Axis = Axis.HORIZONTAL
var is_active: bool = false

func blocks(hit_direction: Vector3) -> bool:
	if not is_active:
		return false
		
	if axis == Axis.ALL:
		return true
	
	var is_vertical := absf(hit_direction.y) > 0.7
	
	match axis:
		Axis.VERTICAL: return is_vertical
		Axis.HORIZONTAL: return not is_vertical
	
	return false
