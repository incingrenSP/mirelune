class_name SkillWheelSlot
extends Control

@onready var skill_icon: TextureRect = $SkillIcon

enum State {
	LOCKED,
	EMPTY,
	EQUIPPED
}

signal selected(slot: SkillWheelSlot)
signal hovered(slot: SkillWheelSlot)
signal unhovered(slot: SkillWheelSlot)

var type_index: int = -1;
var slot_type: SkillData.SkillCategory

var skill_data: SkillData = null
var state: State = State.LOCKED

var start_angle: float = 0.0
var end_angle: float = 0.0

var inner_radius: float = 40.0
var outer_radius: float = 150.0

var is_interactable: bool = true
var is_hovered: bool = false

var hover_tween: Tween

func _ready() -> void:
	resized.connect(_update_pivot)
	
func _update_pivot() -> void:
	pivot_offset = size / 2.0
	
func _draw() -> void:
	var center: Vector2 = size / 2.0
	var color: Color
	
	match state:
		State.LOCKED:
			# also shows locked icon in icon slot
			color = Color(0.2, 0.2, 0.2, 0.75)
			
		State.EMPTY:
			color = Color(0.2, 0.2, 0.2, 0.75)
			
		State.EQUIPPED:
			color = Color.TRANSPARENT
	
	if not is_interactable:
		color = Color(0.0, 0.0, 0.0, 0.0)
	
	if is_hovered and is_interactable:
		color = color.lightened(0.3)
		
	_draw_wedge(
		center,
		inner_radius,
		outer_radius,
		start_angle,
		end_angle,
		color
	)

func _draw_wedge(
	center: Vector2,
	r_in: float,
	r_out: float,
	a_start: float,
	a_end: float,
	color: Color,
	segments: int = 16
) -> void:
	var points := PackedVector2Array()
	
	for j in segments + 1:
		var t := a_start + (a_end - a_start) * j / float(segments)
		points.append(center + Vector2(cos(t), sin(t)) * r_out)
		
	for j in range(segments, -1, -1):
		var t := a_start + (a_end - a_start) * j / float(segments)
		points.append(center + Vector2(cos(t), sin(t)) * r_in)
	
	draw_colored_polygon(points, color)

func _get_base_color() -> Color:
	return Color.MAROON  if slot_type == SkillData.SkillCategory.ACTIVE else Color.WEB_PURPLE

func _update_icon_position() -> void:
	var center := size / 2.0
	var mid_angle := (start_angle + end_angle) / 2.0
	var icon_distance := (inner_radius + outer_radius) / 2.0
	
	var icon_position := center + Vector2(cos(mid_angle), sin(mid_angle)) * icon_distance
	
	skill_icon.position = icon_position - skill_icon.size / 2.0

func setup(
	new_type_index: int,
	new_slot_type: SkillData.SkillCategory,
	new_skill_data: SkillData,
	new_unlocked: bool,
	new_start_angle: float,
	new_end_angle: float
) -> void:
	type_index = new_type_index
	slot_type = new_slot_type
	skill_data = new_skill_data
	start_angle = new_start_angle
	end_angle = new_end_angle
	
	if not new_unlocked:
		state = State.LOCKED
		
	elif skill_data == null:
		state = State.EMPTY
		skill_icon.texture = null
		
	else:
		state = State.EQUIPPED
		skill_icon.texture = skill_data.icon
		
	_update_icon_position()
	queue_redraw()

func contains_point(local_pos: Vector2) -> bool:
	var dist: float = local_pos.length()
	
	if dist <= inner_radius:
		return false
		
	if dist > outer_radius:
		return false
		
	var angle: float = fposmod(local_pos.angle(), TAU)
	var start: float = fposmod(start_angle, TAU)
	var end: float = fposmod(end_angle, TAU)
	
	if start <= end:
		return angle >= start and angle <= end
	else:
		return angle >= start or angle <= end
		
func set_interactable(value: bool, progress: float = 0.0) -> void:
	is_interactable = value
	
	if progress > 0.0:
		is_interactable = false
		return
	
	if not value:
		set_hovered(false)
		
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		self,
		"modulate:a",
		1.0 if value else 0.35,
		0.2
	)
		
	queue_redraw()
	
func set_hovered(value: bool) -> void:
	if value == is_hovered:
		return
		
	is_hovered = value
		
	if hover_tween:
		hover_tween.kill()
	
	var target_scale: Vector2 = Vector2.ONE
	
	if value and is_interactable:
		target_scale = Vector2.ONE * 1.1
		
	hover_tween = create_tween()
	hover_tween.set_trans(Tween.TRANS_QUAD)
	hover_tween.set_ease(Tween.EASE_OUT)
	
	hover_tween.tween_property(
		self,
		"scale",
		target_scale,
		0.15
	)
	
	if value:
		hovered.emit(self)
	else:
		unhovered.emit(self)
	
	queue_redraw()
	
func can_interact() -> bool:
	return is_interactable and state != State.LOCKED
		
func select() -> void:
	print(
		"Slot=",
		"ACTIVE" if slot_type == SkillData.SkillCategory.ACTIVE else "PASSIVE",
		" => Selected"
	)
	if not can_interact():
		return
		
	selected.emit(self)
	
