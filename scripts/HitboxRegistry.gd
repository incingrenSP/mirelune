extends Node

var _hitboxes : Array[Hitbox] = []

func register(hitbox: Hitbox) -> void:
	if not _hitboxes.has(hitbox):
		_hitboxes.append(hitbox)
		
func unregister(hitbox: Hitbox) -> void:
	_hitboxes.erase(hitbox)
	
func find_nearest(point: Vector3, max_distance: float, exclude_faction: String = "") -> Hitbox:
	var best: Hitbox = null
	var best_dist := INF
	
	for hb in _hitboxes:
		if not is_instance_valid(hb):
			continue
		
		if exclude_faction != "" and hb.faction == exclude_faction:
			continue
			
		var d := hb.global_position.distance_to(point)
		
		if d <= max_distance and d < best_dist:
			best = hb
			best_dist = d
			
	return best
