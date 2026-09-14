class_name Projectile
extends Node3D

var skill: SkillData
var instigator: Node3D
var direction: Vector3
var speed: float
var width: float
var max_range: float

var _traveled: float = 0.0
var _hit_targets: Array[Hitbox] = []

@export var spin_speed_deg: float = 0.0

func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	global_position += step
	_traveled += step.length()
	
	print(
		"Projectile:",
		" pos=", global_position,
		" direction=", direction,
		" speed=", speed,
		" step=", step
	)
	
	if spin_speed_deg != 0.0:
		rotate_object_local(Vector3.FORWARD, deg_to_rad(spin_speed_deg) * delta)
	
	_check_hits()
	
	if _traveled >= max_range:
		queue_free()
	
func _ready() -> void:
	add_to_group("active_projectiles")

func _check_hits() -> void:
	var caster_faction := ""
	
	if not skill.indiscriminate:
		var caster_hitbox: Hitbox = instigator.get_node_or_null("Hitbox") as Hitbox
		
		if is_instance_valid(caster_hitbox):
			caster_faction = caster_hitbox.faction
			
	var candidates := HitboxRegistry.find_within(global_position, width, caster_faction)
	
	for hb in candidates:
		if _hit_targets.has(hb):
			continue
		_hit_targets.append(hb)
		hb.receive_hit(instigator, skill, {"origin": global_position, "direction" : direction})
		
		var behavior := skill.behavior
		if behavior is SkillShotBehavior and behavior.shape != SkillShotBehavior.ShotShape.PIERCE:
			queue_free()
			return
		
func launch(
	p_skill: SkillData,
	p_instigator: Node3D,
	p_direction: Vector3,
	p_speed: float,
	p_width: float,
	p_max_range: float,
	origin: Vector3
	) -> void:
		skill = p_skill
		instigator = p_instigator
		direction = p_direction
		speed = p_speed
		width = p_width
		max_range = p_max_range
		
		global_position = origin
		look_at(global_position + direction, Vector3.UP)
	
func would_hit(point: Vector3) -> bool:
	var remaining := max_range - _traveled
	
	if remaining <= 0.0:
		return false
		
	var to_point := point - global_position
	var along := clampf(to_point.dot(direction), 0.0, remaining)
	var closest := global_position + direction * along
	
	return point.distance_to(closest) <= width
