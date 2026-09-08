class_name RangeIndicator
extends Node2D

enum Mode {
	NONE,			# circle only => Lissandra R
	DIRECTIONAL,	# circle + arrow pinned to a rotating angle => Kaisa W
	CONE,			# circle + filled pie slice => Annie W
	RETICLE			# circle +  a dot clamped inside it => Morgana W
}

@export var range_radius: float = 100.0
@export var mode: Mode = Mode.NONE
@export var direction_angle: float = 0.0
@export var cone_angle_degrees: float = 45.0
@export var reticle_local_pos: Vector2 = Vector2.ZERO

@export var circle_color: Color = Color(1, 1, 1, 0.35)
@export var fill_color: Color = Color(1, 0.9, 0.3, 0.25)
@export var line_color: Color = Color(1, 0.9, 0.3, 0.9)
@export var line_width: float = 3.0

func _draw() -> void:
	draw_arc(Vector2.ZERO, range_radius, 0.0, TAU, 64, circle_color, 2.0, true)
	
	match mode:
		Mode.DIRECTIONAL:
			_draw_arrow(Vector2.ZERO, Vector2.RIGHT.rotated(direction_angle) * range_radius)
			
		Mode.CONE:
			_draw_cone()
		
		Mode.RETICLE:
			draw_circle(reticle_local_pos, 8.0, fill_color)
			draw_arc(reticle_local_pos, 8.0, 0.0, TAU, 24, line_color, 2.0, true)
		
		Mode.NONE:
			pass
			
func _draw_arrow(from: Vector2, to: Vector2) -> void:
	draw_line(from, to, line_color, line_width, true)
	
	var back := (from - to).normalized()
	var head_a := to + back.rotated(0.4) * 18.0
	var head_b := to + back.rotated(-0.4) * 18.0
	
	draw_line(to, head_a, line_color, line_width, true)
	draw_line(to, head_b, line_color, line_width, true)
	
func _draw_cone() -> void:
	var half := deg_to_rad(cone_angle_degrees) * 0.5
	var segments := 24
	var points := PackedVector2Array()
	
	points.append(Vector2.ZERO)
	
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := direction_angle - half + t * (half * 2.0)
		
		points.append(Vector2.RIGHT.rotated(angle) * range_radius)
		
	draw_colored_polygon(points, fill_color)
	draw_line(Vector2.ZERO, points[1], line_color, line_width, true)
	draw_line(Vector2.ZERO, points[points.size() - 1], line_color, line_width, true)
	
func refresh() -> void:
	queue_redraw()
	
	
	
	
	
