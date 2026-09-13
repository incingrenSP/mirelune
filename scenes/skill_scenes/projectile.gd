class_name Projectile
extends Node3D

## Spawn one of these when a SKILLSHOT skill resolves (BLAST/BARRAGE/PIERCE - BEAM has
## no travel time, resolve it instantly instead).
## Attach your visual (mesh/particles/trail) as a child in whatever scene you
## instantiate this from - this script only owns movement and hit detection.

var skill: SkillData
var instigator: Node3D
var direction: Vector3
var speed: float
var width: float
var max_range: float

var _traveled: float = 0.0
var _hit_targets: Array[Hitbox] = []

func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	global_position += step
	_traveled += step.length()
	
	_check_hits()
	
	if _traveled >= max_range:
		queue_free()
		
func _check_hits() -> void:
	var caster_faction := ""
	
	if not skill.indiscriminate:
		var caster_hitbox: Hitbox = instigator.get_node_or_null("Hitbox") as Hitbox
		
		if is_instance_valid(caster_hitbox):
			caster_faction = caster_hitbox.faction
			
	var candidates := HitboxRegistry.find_within(global_position, width, caster_faction)
	
	for hb in candidates:
		if _hit_targets.has(hb):
			if _hit_targets.has(hb):
				continue
		_hit_targets.append(hb)
		hb.receive_hit(instigator, skill, {"origin": instigator.global_position, "direction" : direction})
		
		var behavior := skill.behavior
		if behavior is SkillShotBehavior and behavior.shape != SkillShotBehavior.ShotShape.PIERCE:
			queue_free()
			return
		
