class_name RangeIndicator
extends Node3D

enum Mode {
	NONE,			# circle only => Lissandra R
	DIRECTIONAL,	# circle + arrow pinned to a rotating angle => Kaisa W
	CONE,			# circle + filled pie slice => Annie W
	RETICLE			# circle +  a dot clamped inside it => Morgana W
}

@export var range_radius: float = 3.0
@export var mode: Mode = Mode.NONE
@export var direction_angle: float = 0.0
@export var cone_angle_degrees: float = 45.0
@export var reticle_local_pos: Vector3 = Vector3.ZERO

@export var locked: bool = false
@export var cast_progress: float = 0.0

@export var circle_color: Color = Color(1, 1, 1, 0.35)
@export var fill_color: Color = Color(1, 0.9, 0.3, 0.25)
@export var line_color: Color = Color(1, 0.9, 0.3, 0.9)
@export var locked_fill_color: Color = Color(1, 0.2, 0.2, 0.35)
@export var locked_line_color: Color = Color(1, 0.2, 0.2, 0.9)

@export var y_offset: float = 0.02
@export var line_width: float = 0.08
@export var arrow_head_length: float = 0.5

var _fill_mesh: MeshInstance3D
var _line_mesh: MeshInstance3D

func _ready() -> void:
	_fill_mesh = MeshInstance3D.new()
	_line_mesh = MeshInstance3D.new()
	
	add_child(_fill_mesh)
	add_child(_line_mesh)
	
	_fill_mesh.material_override = _make_material()
	_line_mesh.material_override = _make_material()
	
	refresh()
	
func _make_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	mat.no_depth_test = true
	mat.render_priority = 1
	mat.vertex_color_use_as_albedo = true
	
	return mat

func _rebuild_fill(color: Color) -> void:
	var st := SurfaceTool.new()
	var added := false
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(color)
	
	match mode:
		Mode.CONE:
			var half := deg_to_rad(cone_angle_degrees) * 0.5
			_add_wedge_fill(st, Vector3.ZERO, range_radius, direction_angle - half, direction_angle + half, 24)
			
		Mode.RETICLE:
			_add_wedge_fill(st, reticle_local_pos, 0.25, 0.0, TAU, 16)
			added = true
			
		_:
			pass
			
	if locked:
		st.set_color(color)
		_add_wedge_fill(st, Vector3.ZERO, 0.4, -PI * 0.5, -PI * 0.5 + TAU * cast_progress, 24)
		added = true
		
	_fill_mesh.mesh = st.commit() if added else null

func _rebuild_lines(color: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(circle_color)
	
	_add_circle_outline(st, Vector3.ZERO, range_radius, 64, line_width * 0.6)
	
	st.set_color(color)
	match mode:
		Mode.DIRECTIONAL:
			_add_arrow(st)
		Mode.CONE:
			var half := deg_to_rad(cone_angle_degrees) * 0.5
			var p0 := Vector3(cos(direction_angle - half), 0.0, sin(direction_angle - half)) * range_radius
			var p1 := Vector3(cos(direction_angle + half), 0.0, sin(direction_angle + half)) * range_radius
			_add_line_quad(st, Vector3.ZERO, p0, line_width)
			_add_line_quad(st, Vector3.ZERO, p1, line_width)
		Mode.RETICLE:
			_add_circle_outline(st, reticle_local_pos, 0.25, 24, line_width * 0.6)
		Mode.NONE:
			pass

	_line_mesh.mesh = st.commit()

func _add_arrow(st: SurfaceTool) -> void:
	var fwd := Vector3(cos(direction_angle), 0.0, sin(direction_angle))
	var to := fwd * range_radius
	_add_line_quad(st, Vector3.ZERO, to, line_width)
	var back := -fwd
	var head_a := to + back.rotated(Vector3.UP, 0.4) * arrow_head_length
	var head_b := to + back.rotated(Vector3.UP, -0.4) * arrow_head_length
	_add_line_quad(st, to, head_a, line_width)
	_add_line_quad(st, to, head_b, line_width)

func _add_circle_outline(st: SurfaceTool, center: Vector3, radius: float, segments: int, width: float) -> void:
	for i in range(segments):
		var a0 := TAU * float(i) / segments
		var a1 := TAU * float(i + 1) / segments
		var p0 := center + Vector3(cos(a0), 0.0, sin(a0)) * radius
		var p1 := center + Vector3(cos(a1), 0.0, sin(a1)) * radius
		_add_line_quad(st, p0, p1, width)

func _add_wedge_fill(st: SurfaceTool, center: Vector3, radius: float, angle_start: float, angle_end: float, segments: int) -> void:
	var top := center + Vector3.UP * y_offset
	for i in range(segments):
		var t0 := float(i) / segments
		var t1 := float(i + 1) / segments
		var a0 : float = lerp(angle_start, angle_end, t0)
		var a1 : float = lerp(angle_start, angle_end, t1)
		var p0 := center + Vector3(cos(a0), 0.0, sin(a0)) * radius + Vector3.UP * y_offset
		var p1 := center + Vector3(cos(a1), 0.0, sin(a1)) * radius + Vector3.UP * y_offset
		st.add_vertex(top)
		st.add_vertex(p0)
		st.add_vertex(p1)
		
func _add_line_quad(st: SurfaceTool, from_xz: Vector3, to_xz: Vector3, width: float) -> void:
	var from := from_xz + Vector3.UP * y_offset
	var to := to_xz + Vector3.UP * y_offset
	var dir := to - from
	if dir.length() < 0.0001:
		return
	dir = dir.normalized()
	var perp := Vector3(-dir.z, 0.0, dir.x) * (width * 0.5)
	st.add_vertex(from + perp)
	st.add_vertex(from - perp)
	st.add_vertex(to - perp)
	st.add_vertex(from + perp)
	st.add_vertex(to - perp)
	st.add_vertex(to + perp)

func refresh() -> void:
	if not is_instance_valid(_fill_mesh):
		return
		
	var fc := locked_fill_color if locked else fill_color
	var lc := locked_line_color if locked else line_color
	
	_rebuild_fill(fc)
	_rebuild_lines(lc)
