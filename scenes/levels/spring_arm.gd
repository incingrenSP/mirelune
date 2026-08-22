extends Node3D

@export var camera: Camera3D

func _process(delta: float) -> void:
	if camera:
		var cam_pos = camera.global_position
		cam_pos.y = global_position.y
		look_at(cam_pos, Vector3.UP)
