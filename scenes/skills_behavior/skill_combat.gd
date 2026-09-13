class_name SkillCombat

static func _caster_faction(skill: SkillData, instigator: Node3D) -> String:
	if skill.indiscriminate or not is_instance_valid(instigator):
		return ""
		
	var hb := instigator.get_node_or_null("Hitbox") as Hitbox
	
	return hb.faction if is_instance_valid(hb) else ""
	
static func resolve_delayed_hit(
	skill: SkillData,
	instigator: Node3D,
	target_data: Dictionary,
	delay: float = 0.0,
	target: Hitbox = null,
	point: Vector3 = Vector3.ZERO,
	radius: float = 0.0
) -> void:
	if delay > 0.0 and is_instance_valid(instigator):
		await instigator.get_tree().create_timer(delay).timeout
		
	if is_instance_valid(target):
		target.receive_hit(instigator, skill, target_data)
		return
		
	if radius <= 0.0:
		return
		
	var exclude := _caster_faction(skill, instigator)
	
	for hb in HitboxRegistry.find_within(point, radius, exclude):
		hb.receive_hit(instigator, skill, target_data)
		
static func resolve_beam(skill: SkillData, instigator: Node3D, target_data: Dictionary) -> void:
	var origin: Vector3 = target_data.get("origin", instigator.global_position)
	var direction: Vector3 = target_data["direction"]
	var behavior := skill.behavior
	var width: float = behavior.width if behavior is SkillShotBehavior else 0.5
	
	var exclude := _caster_faction(skill, instigator)
	
	var range_len := skill.range_value
	
	var point := origin + direction * (range_len * 0.5)
	var max_dist := range_len * 0.5 + width
	
	for hb in HitboxRegistry.find_within(point, max_dist, exclude):
		var to_hb := hb.global_position - origin
		var along := clampf(to_hb.dot(direction), 0.0, range_len)
		var closest := origin + direction * along
		
		if hb.global_position.distance_to(closest) <= width:
			hb.receive_hit(instigator, skill, target_data)
			
static func resolve_aoe_circle(skill: SkillData, instigator: Node3D, target_data: Dictionary) -> void:
	pass
