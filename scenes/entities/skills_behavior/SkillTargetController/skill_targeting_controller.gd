class_name SkillTargetingController
extends Node2D

signal targeting_confirmed(skill: SkillData, target_data: Dictionary)
signal targeting_canceled

@export var caster: Node2D

var active_skill: SkillData
var is_targeting: bool = false

var _indicator: RangeIndicator
var _last_angle: float = 0.0
var _last_reticle_local: Vector2 = Vector2.ZERO

func _ensure_indicator() -> void:
	if _indicator != null:
		return
		
	_indicator = RangeIndicator.new()
	caster.add_child(_indicator)
	_indicator.position = Vector2.ZERO
	
func _configure_indicator_for_skill() -> void:
	_indicator.range_radius = active_skill.range_value
	
	match active_skill.attack_type:
		SkillData.AttackType.SKILLSHOT:
			_indicator.mode = RangeIndicator.Mode.DIRECTIONAL
		SkillData.AttackType.SUREHIT:
			_indicator.mode = RangeIndicator.Mode.RETICLE
		SkillData.AttackType.AOE:
			var behavior := active_skill.behavior
			
			if behavior is AOEBehavior and behavior.shape == AOEBehavior.AOEShape.CONE:
				_indicator.mode = RangeIndicator.Mode.CONE
				_indicator.cone_angle_degrees = behavior.cone_angle
				
			else:
				_indicator.mode = RangeIndicator.Mode.RETICLE
				
	_indicator.refresh()
	
func _update_pointer(mouse_global_pos: Vector2) -> void:
	var to_mouse := mouse_global_pos - caster.global_position
	
	if to_mouse.length() < 0.001:
		to_mouse = Vector2.RIGHT
		
	_last_angle = to_mouse.angle()
	_last_reticle_local = to_mouse.limit_length(_indicator.range_radius)
	
	_indicator.direction_angle = _last_angle
	_indicator.reticle_local_pos = _last_reticle_local
	_indicator.refresh()
	
func _build_target_data() -> Dictionary:
	var data := {}
	
	match active_skill.attack_type:
		SkillData.AttackType.SKILLSHOT:
			data["origin"] = caster.global_position
			data["direction"] = Vector2.RIGHT.rotated(_last_angle)
			
		SkillData.AttackType.SUREHIT:
			data["target_point"] = caster.global_position + _last_reticle_local
			
		SkillData.AttackType.AOE:
			var behavior := active_skill.behavior
			
			if behavior is AOEBehavior and behavior.shape == AOEBehavior.AOEShape.CONE:
				data["origin"] = caster.global_position
				data["direction"] = Vector2.RIGHT.rotated(_last_angle)
			
			else:
				data["target_point"] = caster.global_position + _last_reticle_local
			
	return data
	
func _stop() -> void:
	is_targeting = false
	active_skill = null
	
	if _indicator:
		_indicator.visible = false
		
	set_process_unhandled_input(false)
	
func _confirm_targeting() -> void:
	if not is_targeting:
		return
		
	var target_data := _build_target_data()
	var skill := active_skill
	
	_stop()
	
	targeting_confirmed.emit(skill, target_data)
	
func _unhandled_input(event: InputEvent) -> void:
	if not is_targeting:
		return
		
	if event is InputEventMouseMotion:
		_update_pointer(get_global_mouse_position())
		
	if event.is_action_pressed("ui_cancel"):
		cancel_targeting()
		
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_confirm_targeting()
		
		elif event.button_index == MOUSE_BUTTON_MASK_RIGHT:
			cancel_targeting()

func start_targeting(skill: SkillData) -> void:
	if skill == null:
		push_warning("SkillTargetingController: SkillData is null")
		return
		
	if skill.category == SkillData.SkillCategory.ACTIVE:
		push_warning("SkillTargetingController: tried to target a non-ACTIVE skill (%s)" % [skill.id])
		return

	if caster == null:
		push_error("SkillTargetingController: caster not set")
		return
		
	active_skill = skill
	is_targeting = true
	
	_ensure_indicator()
	_configure_indicator_for_skill()
	
	_indicator.visible = true
	
	set_process_unhandled_input(true)
	_update_pointer(get_global_mouse_position())
	
func cancel_targeting() -> void:
	if not is_targeting:
		return
		
	_stop()
	targeting_canceled.emit()
