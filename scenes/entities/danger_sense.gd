class_name DangerSense
extends Node

signal danger_detected(threat: Dictionary)
'''
{
	kind : shape | projectile | surehit
	skill : SkillData,
	time to impact : float,
	source : Node3D,
	[shape/projectile only] "target_data": Dictionary,
	[projectile only] "projectile": Projectile,
	[surehit only] "caster": SkillTargetingController
}
'''

@export var scan_interval: float = 0.15;
@export var owner_entity: Node3D

var _timer: float = 0.0

func _ready() -> void:
	if owner_entity == null:
		owner_entity = get_parent() as Node3D
		
func _process(delta: float) -> void:
	_timer -= delta
	
	if _timer <= 0.0:
		_timer = scan_interval
		
		var threat := scan()
		if not threat.is_empty():
			danger_detected.emit(threat)

'''
should return the threat thats soonest (?) idk if that's a word
so say someone uses draco meteor: entity doesn't need to bother with meteors
that don't hit, or if none of the trajectories fall in entity's immediate position
continue their state
returns the single soonest threat
to not make it op, instead of trajectory, entities instead check for active_skill projectile
currently in the world
so if skill hit has lower trajectory, entities can prolly walk out
if its fast, not enough time to react so they either guard or they get hit
also could make hit radius large for some skills so that even if entities react to the projectile
there wont be enough time/space to avoid the hit, and the guard skills dont actually block against
given type of hit: say a xz guard cannot block a y hit
'''

'''
working:
	skip self hitbox (unless its something like a self sacrifice)
	if attack is surehit => 
'''

func scan() -> Dictionary:
	if not is_instance_valid(owner_entity):
		return {}
		
	var best: Dictionary = {}
	var best_ttl := INF
	var my_hitbox: Hitbox = owner_entity.get_node_or_null("Hitbox") as Hitbox
	
	for caster in get_tree().get_nodes_in_group("active_casters"):
		if not (caster is SkillTargetingController):
			continue
			
		if caster.caster == owner_entity:
			continue
			
		if caster.state != SkillTargetingController.State.CASTING:
			continue
			
		var skill: SkillData = caster.active_skill
		
		if skill == null:
			continue
			
		if skill.attack_type == SkillData.AttackType.SUREHIT:
			var target_data: Dictionary = caster._cast_target_data()
			if SkillCombat.would_hit_point(skill, target_data, owner_entity.global_position):
				if caster._cast_time_remaining < best_ttl:
					best_ttl = caster._cast_time_remaining
					best = {
						"kind": "shape",
						"skill": skill,
						"time_to_impact": best_ttl,
						"target_data": target_data,
						"source": caster.caster
					}
		
	for proj in get_tree().get_nodes_in_group("active_projectiles"):
		if not (proj is Projectile) or proj.instigator == owner_entity:
			continue
			
		if proj.would_hit(owner_entity.global_position):
			var dist: Vector3 = proj.global_position.distance_to(owner_entity.global_position)
			var ttl: float = dist / max(proj.speed, 0.01)
			
			if ttl < best_ttl:
				best_ttl = ttl
				best = {
					"kind": "projectile",
					"skill": proj.skill,
					"time_to_impact": ttl,
					"projectile": proj,
					"source": proj.instigator
				}
			
	return best
