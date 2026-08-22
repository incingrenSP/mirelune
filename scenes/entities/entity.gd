class_name Entity
extends CharacterBody3D

@export var max_hp: float = 100.0

var hp: float:
	set(value):
		hp = clamp(value, 0.0, max_hp)
var displayed_hp_pct := 1.0
var displayed_sp_pct := 1.0

@export var bar_smooth_speed := 2.5

@onready var focus_point: Marker3D = $CameraFocusPoint
		
func _ready():
	hp = max_hp
	
func gameplay_locked():
	return not GameStateManager.is_gameplay_active()
	
func _physics_process(delta: float) -> void:
	if gameplay_locked():
		velocity.x = 0.0
		velocity.z = 0.0
		return
