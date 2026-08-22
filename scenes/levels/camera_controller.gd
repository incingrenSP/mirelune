class_name CameraController
extends Node3D

@onready var spring_arm: SpringArm3D = $SpringArm3D

# dialog portion
@export var dialog_zoom_speed := 3.0
@export var dialog_distance := 8.0

# player portion
@export var default_distance := 12.0
@export var follow_speed := 5.0
@export var rotation_speed := 90.0

var default_target: Marker3D
var focus_target: Marker3D

var focus_offset: Vector3 = Vector3.ZERO
var target_spring_length: float

func _ready() -> void:
	add_to_group("camera")
	DialogManager.register_camera(self)
	
	target_spring_length = default_distance
	spring_arm.spring_length = default_distance
		
func _process(delta: float) -> void:
	var target := focus_target if focus_target else default_target
	if target:
		var desired_position := target.global_position + focus_offset
		var weight := 1.0 - exp(-follow_speed * delta)
		global_position = global_position.lerp(
			desired_position,
			weight
		)
		
	spring_arm.spring_length = move_toward(
		spring_arm.spring_length,
		target_spring_length,
		dialog_zoom_speed * delta
	)

func _unhandled_input(event: InputEvent) -> void:
	if focus_target != null:
		return
		
	# camera rotation if i need

func set_default_target(target: Marker3D) -> void:
	default_target = target

func focus_on(
	target: Marker3D,
	offset: Vector3 = Vector3.ZERO
) -> void:
	focus_target = target
	focus_offset = offset
	target_spring_length = dialog_distance

func release_focus() -> void:
	focus_target = null
	focus_offset = Vector3.ZERO
	target_spring_length = default_distance
	
