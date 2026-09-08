class_name PlayerSkillInput
extends Node

@export var targeting: SkillTargetingController
@export var camera: Camera3D

func _unhandled_input(event: InputEvent) -> void:
	if targeting == null or not targeting.is_aiming():
		return
		
	if event is InputEventMouseMotion:
		var world_point: Variant = _mouse_to_ground_point(event.position)
		
		if world_point != null:
			targeting.update_aim(world_point)
			
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			targeting.confirm()
			
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			targeting.cancel()
			
	elif event.is_action_pressed("ui_cancel"):
		targeting.cancel()
			
func _mouse_to_ground_point(screen_pos: Vector2) -> Variant:
	if camera == null or not is_instance_valid(targeting) or not is_instance_valid(targeting.caster):
		return null
	
	var ground_y := targeting.caster.global_position.y
	var plane := Plane(Vector3.UP, ground_y)
	var from: Vector3 = camera.project_ray_origin(screen_pos)
	var dir: Vector3 = camera.project_ray_normal(screen_pos)
	
	var result: Variant = plane.intersects_ray(from, dir)
	
	if result == null:
		return null
	
	return result as Vector3
