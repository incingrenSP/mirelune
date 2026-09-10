class_name SkillTargetingController
extends Node3D

enum State {
	IDLE,
	AIMING,
	CASTING
}

signal aim_updated(skill: SkillData, target_data: Dictionary)
signal targeting_started(skill: SkillData)
signal cast_started(skill: SkillData, target_data: Dictionary)
signal cast_completed(skill: SkillData, target_data: Dictionary)
signal cast_cancelled(skill: SkillData)

@export var caster: Node3D
@export var stat_component: StatComponent
@export var exclude_own_faction: bool = true

var state: State = State.IDLE
var active_skill: SkillData

var _indicator: RangeIndicator
var _last_angle: float = 0.0
var _last_world_offset: Vector3 = Vector3.ZERO
#var _last_reticle_local: Vector3 = Vector3.ZERO
var _cast_time_total: float = 0.0
var _cast_time_remaining: float = 0.0

var _cast_target_data: Dictionary = {}
var _caster_hitbox: Hitbox

func _ready() -> void:
	if caster == null:
		caster = get_parent() as Node3D
		
	if stat_component == null and is_instance_valid(caster):
		stat_component = caster.get_node_or_null("StatComponent") as StatComponent
	
	if is_instance_valid(caster):
		_caster_hitbox = caster.get_node_or_null("Hitbox") as Hitbox
	
	set_process(false)
	
func _process(delta: float) -> void:
	if state != State.CASTING:
		set_process(false)
		return
		
	_cast_time_remaining -= delta
	var progress: float = clamp(1 - (_cast_time_remaining / max(_cast_time_total, 0.001)), 0.0, 1.0)
	
	if is_instance_valid(caster.casting_progress_ui):
		caster.set_progress_ui(progress)
	
	if _cast_time_remaining <= 0.0:
		_complete_cast()
	
func _complete_cast() -> void:
	var skill := active_skill
	var target_data := _cast_target_data
	
	_reset_state()
	
	cast_completed.emit(skill, target_data)
	
func _reset_state() -> void:
	state = State.IDLE
	_cast_target_data.clear()
	
	active_skill = null
	set_process(false)
	
	if is_instance_valid(_indicator):
		_indicator.visible = false
		
	if is_instance_valid(caster.casting_progress_ui):
		caster.stop_progress_ui()

func _ensure_indicator() -> void:
	if is_instance_valid(_indicator):
		return
		
	_indicator = RangeIndicator.new()
	caster.add_child(_indicator)
	_indicator.position = Vector3.ZERO
	
func _configure_indicator_for_skill() -> void:
	_indicator.range_radius = active_skill.range_value
	
	match active_skill.attack_type:
		SkillData.AttackType.SKILLSHOT:
			_indicator.mode = RangeIndicator.Mode.DIRECTIONAL
			
		SkillData.AttackType.SUREHIT:
			_indicator.mode = RangeIndicator.Mode.RETICLE
			
		SkillData.AttackType.AOE:
			var behavior := active_skill.behavior
			
			if behavior is AOEBehavior:
				if behavior.shape == AOEBehavior.AOEShape.CONE:
					_indicator.mode = RangeIndicator.Mode.CONE
					_indicator.cone_angle_degrees = behavior.cone_angle
				
				elif behavior.shape == AOEBehavior.AOEShape.CIRCLE:
					_indicator.mode = RangeIndicator.Mode.CIRCLE
					_indicator.circle_radius = behavior.aoe_radius
				
			else:
				_indicator.mode = RangeIndicator.Mode.RETICLE
				
	_indicator.refresh()
	
func _build_target_data() -> Dictionary:
	var data := {}
	
	match active_skill.attack_type:
		SkillData.AttackType.SKILLSHOT:
			data["origin"] = caster.global_position
			data["direction"] = Vector3(cos(_last_angle), 0.0, sin(_last_angle))
			
		SkillData.AttackType.SUREHIT:
			data["target_point"] = caster.global_position + _last_world_offset
			
		SkillData.AttackType.AOE:
			var behavior := active_skill.behavior
			
			if behavior is AOEBehavior and behavior.shape == AOEBehavior.AOEShape.CONE:
				data["origin"] = caster.global_position
				data["direction"] = Vector3(cos(_last_angle), 0.0, sin(_last_angle))
				
			else:
				data["target_point"] = caster.global_position + _last_world_offset
				
	return data
	
func _recompute_pointer(world_point: Vector3) -> void:
	var delta := world_point - caster.global_position
	var flat := Vector3(delta.x, 0.0, delta.z)
	
	if flat.length() < 0.001:
		flat = Vector3.RIGHT

	_last_angle = atan2(flat.z, flat.x)
	_last_world_offset = flat.limit_length(_indicator.range_radius)
	
	var local_flat: Vector3 = caster.global_transform.basis.inverse() * flat

	_indicator.direction_angle = atan2(local_flat.z, local_flat.x)
	_indicator.reticle_local_pos = local_flat.limit_length(_indicator.range_radius)

func _resolve_surehit_target() -> Hitbox:
	var behavior := active_skill.behavior
	var lock_radius := 1.0
	
	if behavior is SureHitBehavior:
		lock_radius = behavior.lock_on_radius
		
	var aim_point := caster.global_position + _last_world_offset
	var exclude := ""
	
	if exclude_own_faction and is_instance_valid(_caster_hitbox):
		exclude = _caster_hitbox.faction
		
	return HitboxRegistry.find_nearest(aim_point, lock_radius, exclude)

func start_targeting(skill: SkillData) -> void:
	if skill == null:
		push_warning("SkillTargetingController: SkillData is null")
		return
		
	if skill.category != SkillData.SkillCategory.ACTIVE:
		push_warning("SkillTargetingController: tried to target a non-ACTIVE skill (%s)" % [skill.id])
		return

	if caster == null:
		push_error("SkillTargetingController: caster not set")
		return
		
	active_skill = skill
	state = State.AIMING
		
	_ensure_indicator()
	
	_indicator.top_level = false
	_indicator.position = Vector3.ZERO
	_indicator.rotation = Vector3.ZERO
	
	_configure_indicator_for_skill()
	
	_indicator.visible = true
	
	targeting_started.emit(active_skill)
	
	var facing := -caster.global_transform.basis.z
	update_aim(caster.global_position + facing)
	
func update_aim(world_point: Vector3) -> void:
	if state != State.AIMING:
		return
	
	_recompute_pointer(world_point)
	_indicator.refresh()
	aim_updated.emit(active_skill, _build_target_data())	

func confirm() -> void:
	if state != State.AIMING:
		return
		
	_cast_target_data = _build_target_data()
	
	if active_skill.attack_type == SkillData.AttackType.SUREHIT:
		_cast_target_data["target_entity"] = _resolve_surehit_target()
	
	state = State.CASTING
	
	var yaw := caster.global_rotation.y
	_indicator.top_level = true
	_indicator.global_transform = Transform3D(Basis(Vector3.UP, yaw), caster.global_position)
	
	var cast_speed := 1.0
	
	if is_instance_valid(stat_component):
		var raw_speed: float = stat_component.get_stat(StatModifierEntry.StatType.CAST_SPEED)
		
		if raw_speed > 0.0:
			cast_speed = raw_speed
			
	_cast_time_total = max(active_skill.cast_time / cast_speed, 0.0)
	_cast_time_remaining = _cast_time_total
	
	if is_instance_valid(caster.casting_progress_ui):
		caster.start_progress_ui()
		
	cast_started.emit(active_skill, _cast_target_data)
	
	if _cast_time_total <= 0.0:
		_complete_cast()
		
	else:
		set_process(true)

func cancel() -> void:
	if state == State.IDLE:
		return
		
	var skill := active_skill
	
	_reset_state()
	cast_cancelled.emit(skill)
	
func is_aiming() -> bool:
	return state == State.AIMING
