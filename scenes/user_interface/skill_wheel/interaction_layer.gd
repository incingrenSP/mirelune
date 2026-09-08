class_name SkillWheelInteraction
extends Control

var wheel: SkillWheel
var hovered_element: Control = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func setup(skill_wheel: SkillWheel) -> void:
	wheel = skill_wheel

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover(event.position)
		
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_select_hovered_element()
			
func _update_hover(mouse_position: Vector2) -> void:
	var wheel_position: Vector2 = mouse_position - size / 2.0
	var new_element = _get_hovered_element(wheel_position)

	# if hovered element has not changed return
	if new_element == hovered_element:
		return
		
	# Set current hovered element to false
	if hovered_element:
		hovered_element.set_hovered(false)
		
	# switch to new hovered element
	hovered_element = new_element
	
	# set current hovered element to true
	if hovered_element:
		hovered_element.set_hovered(true)
		
func _select_hovered_element() -> void:
	if hovered_element:
		hovered_element.select()
	
func _get_hovered_element(local_position: Vector2):
	if wheel.core.can_interact() and wheel.core.contains_point(local_position):
		return wheel.core
		
	for slot in wheel.slots:
		if slot.can_interact() and slot.contains_point(local_position):
			return slot
			
	return null
