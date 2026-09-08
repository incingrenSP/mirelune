class_name SkillWheelCore
extends Control

enum State {
	LOCKED,
	EMPTY,
	EQUIPPED
}

signal core_selected
signal core_hovered
signal core_unhovered

var core_skill: SkillData = null
var state: State = State.LOCKED

@export var core_radius: float

var is_interactable: bool = true
var is_hovered: bool = false

var hover_tween: Tween
	
func _ready() -> void:
	resized.connect(_update_pivot)
	
func _update_pivot() -> void:
	pivot_offset = size / 2.0
	
func _draw() -> void:
	var center: Vector2 = size / 2.0
	var core_color: Color
	
	match state:
		State.LOCKED:
			core_color = Color.TRANSPARENT
			
		State.EMPTY:
			core_color = Color(1.0, 1.0, 1.0, 0.55)
			
		State.EQUIPPED:
			core_color = Color.ANTIQUE_WHITE
	
	if not is_interactable:
		core_color = Color.TRANSPARENT
	
	if is_hovered and is_interactable:
		core_color = core_color.lightened(0.3)
		
	draw_circle(
		center,
		core_radius,
		core_color
	)
	
func setup(
	new_skill: SkillData,
	new_unlocked: bool
) -> void:
	core_skill = new_skill
	
	if not new_unlocked:
		state = State.LOCKED
		
	elif core_skill == null:
		state = State.EMPTY
		
	else:
		state = State.EQUIPPED
		
	queue_redraw()

func contains_point(local_pos: Vector2) -> bool:
	return local_pos.length() <= core_radius

func set_hovered(value: bool) -> void:
	if value == is_hovered:
		return
		
	is_hovered = value
	
	if hover_tween:
		hover_tween.kill()
	
	var target_scale: Vector2 = Vector2.ONE
	
	if value and is_interactable:
		target_scale = Vector2.ONE * 1.2
		
	hover_tween = create_tween()
	
	hover_tween.tween_property(
		self,
		"scale",
		target_scale,
		0.15
	)
	
	if value:
		core_hovered.emit()
	else:
		core_unhovered.emit()
	
	queue_redraw()

func set_interactable(value: bool) -> void:
	is_interactable = value
	
	if not value:
		set_hovered(true)
		
	queue_redraw()
	
func can_interact() -> bool:
	return is_interactable and state != State.LOCKED
	
func select() -> void:
	if not can_interact():
		return
		
	core_selected.emit()
	
func set_skill(skill_id: String):
	return
