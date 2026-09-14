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



func scan() -> Dictionary:
	return {}
