class_name SkillCooldownOverlay
extends Control

@export var overlay_color: Color = Color(0.0, 0.0, 0.0, 0.55)
@export var cooldown_label: Label

var radius: float = 150.0
var progress: float = 1.0

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
func _draw() -> void:
	if progress >= 1.0:
		return
	
	var center: Vector2 = size / 2.0
	var remaining_fraction: float = 1.0 - progress
	var sweep: float = remaining_fraction * TAU
	
	var start_angle: float = -PI / 2.0
	var end_angle: float = start_angle + sweep
	
	_draw_pie(center, radius, start_angle, end_angle, overlay_color)
	
func _draw_pie(
	center: Vector2,
	radius: float,
	a_start: float,
	a_end: float,
	color: Color,
	segments: int = 32
) -> void:
	var points := PackedVector2Array()
	points.append(center)
	
	for j in segments + 1:
		var t := a_start + (a_end - a_start) * j / float(segments)
		var point := center + Vector2(cos(t), sin(t)) * radius
		points.append(point)
		
	draw_colored_polygon(points, color)
	
func set_progress(value: float) -> void:
	progress = clamp(value, 0.0, 1.0)
	visible = progress < 1.0
	queue_redraw()
	
