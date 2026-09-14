class_name SkillCombat

static func _caster_faction(skill: SkillData, instigator: Node3D) -> String:
	if skill.indiscriminate or not is_instance_valid(instigator):
		return ""
		
	var hb := instigator.get_node_or_null("Hitbox") as Hitbox
	
	return hb.faction if is_instance_valid(hb) else ""
	
static func _launch_projectile(skill: SkillData, instigator: Node3D, target_data: Dictionary, behavior: SkillShotBehavior, delay: float) -> void:
	if delay > 0.0:
		await instigator.get_tree().create_timer(delay).timeout
		if not is_instance_valid(instigator):
			return

	var proj: Projectile = behavior.projectile_scene.instantiate()
	instigator.get_tree().current_scene.add_child(proj)
	
	proj.launch(skill, instigator, target_data["direction"], behavior.projectile_speed, behavior.width, skill.range_value, target_data["origin"])
	
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

# Neuvillete CA: so basically hits everyone in a straight line: origin (user pos) to skill range. origin + direction * range
# beam has some width to it, albeit a skillshot, it can hit multiple enemies (also despite not being a burst or a pierce)

static func resolve_beam(skill: SkillData, instigator: Node3D, target_data: Dictionary) -> void:
	var origin: Vector3 = target_data.get("origin", instigator.global_position)
	var direction: Vector3 = target_data["direction"]
	var behavior := skill.behavior
	var width: float = behavior.width if behavior is SkillShotBehavior else 0.5

	var exclude := _caster_faction(skill, instigator)
	var range_len := skill.range_value
	
	for hb in HitboxRegistry.find_within(origin + direction * (range_len * 0.5), range_len * 0.5 + width, exclude):
		if would_hit_point(skill, target_data, hb.global_position):
			hb.receive_hit(instigator, skill, target_data)

# orianna w: instant hit in an area. hits within range_value of target_point

static func resolve_aoe_circle(skill: SkillData, instigator: Node3D, target_data: Dictionary) -> void:
	var point: Vector3 = target_data["target_point"]
	var exclude := _caster_faction(skill, instigator)
	
	for hb in HitboxRegistry.find_within(point, skill.range_value, exclude):
		hb.receive_hit(instigator, skill, target_data)

# dragon breath?: hits everyone within a cone range

static func resolve_aoe_cone(skill: SkillData, instigator: Node3D, target_data: Dictionary) -> void:
	var origin: Vector3 = target_data["origin"]
	var direction: Vector3 = target_data["direction"]
	var behavior := skill.behavior
	var half_angle_rad := deg_to_rad((behavior.cone_angle if behavior is AOEBehavior else 45.0) * 0.5)

	var exclude := _caster_faction(skill, instigator)
	
	for hb in HitboxRegistry.find_within(origin, skill.range_value, exclude):
		var to_hb := (hb.global_position - origin)
		to_hb.y = 0.0
		
		if to_hb.length() < 0.001:
			continue
			
		var angle := direction.angle_to(to_hb.normalized())
		
		if angle <= half_angle_rad:
			hb.receive_hit(instigator, skill, target_data)
			
static func resolve_surehit(skill: SkillData, instigator: Node3D, target_data: Dictionary) -> void:
	var target: Hitbox = target_data.get("target_entity")
	if not is_instance_valid(target):
		return

	var behavior := skill.behavior
	var hit_count: int = behavior.hit_count if behavior is SureHitBehavior else 1
	var hit_interval: float = behavior.hit_interval if behavior is SureHitBehavior else 0.0

	for i in hit_count:
		resolve_delayed_hit(skill, instigator, target_data, i * hit_interval, target)

static func resolve_skillshot(skill: SkillData, instigator: Node3D, target_data: Dictionary) -> void:
	var behavior := skill.behavior
	if not (behavior is SkillShotBehavior):
		push_warning("SkillCombat: '%s' has no SkillshotBehavior" % skill.id)
		return

	if behavior.shape == SkillShotBehavior.ShotShape.BEAM:
		resolve_beam(skill, instigator, target_data)
		return

	if behavior.projectile_scene == null:
		push_warning("SkillCombat: '%s' has no projectile_scene assigned" % skill.id)
		return

	print("SkillShot resolve registered")
	var shots: int = behavior.barrage_count if behavior.shape == SkillShotBehavior.ShotShape.BARRAGE else 1
	for i in shots:
		_launch_projectile(skill, instigator, target_data, behavior, i * behavior.barrage_interval)

static func resolve_melee(skill: SkillData, instigator: Node3D, range: float) -> void:
	var exclude := _caster_faction(skill, instigator)
	var target := HitboxRegistry.find_nearest(instigator.global_position, range, exclude)
	
	if not is_instance_valid(target):
		return
		
	var dir := target.global_position - instigator.global_position
	dir.y = 0.0
	
	var direction := dir.normalized() if dir.length() > 0.001 else Vector3.FORWARD
	
	target.receive_hit(instigator, skill, {"origin" : instigator.global_position, "direction" : direction})

static func would_hit_point(skill: SkillData, target_data: Dictionary, point: Vector3) -> bool:
	match skill.attack_type:
		SkillData.AttackType.SKILLSHOT:
			var behavior := skill.behavior
			
			if not (behavior is SkillShotBehavior):
				return false
				
			var origin: Vector3 = target_data.get("origin", Vector3.ZERO)
			var direction: Vector3 = target_data["direction"]
			var width: float = behavior.width
			var to_point := point - origin
			var along := clampf(to_point.dot(direction), 0.0, skill.range_value)
			var closest := origin + direction * along
			
			return point.distance_to(closest) <= width
		
		SkillData.AttackType.AOE:
			var behavior := skill.behavior
			
			if behavior is AOEBehavior and behavior.shape == AOEBehavior.AOEShape.CONE:
				var origin: Vector3 = target_data["origin"]
				var direction: Vector3 = target_data["direction"]
				var half_angle_rad := deg_to_rad(behavior.cone_angle * 0.5)
				var to_point := point - origin
				
				to_point.y = 0.0
				
				if to_point.length() < 0.001:
					return true
					
				return direction.angle_to(to_point.normalized()) <= half_angle_rad
			
			else:
				var center: Vector3 = target_data["target_point"]
				
				return point.distance_to(center) <= skill.range_value
				
	return false
