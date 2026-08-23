extends Area3D

@export var enemy: Enemy
var times_hovered: int = 0
var hovered: bool = false

func _ready() -> void:
	'''
	signals to connect
	'''
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

func _on_mouse_entered():
	set_hovered(true)
	
func _on_mouse_exited():
	set_hovered(false)
	
func set_hovered(value: bool):
	if GameStateManager.is_dialog_active():
		return
	'''
	send signal to set resource bar toggle to visible temporarily if not in combat
	'''
	hovered = value
	if enemy:
		print("Enemy detected!")
		enemy.is_hovered = value
		enemy.resource_bar_visibility()
	
func _on_input_event(
	camera, event, position, normal, shape_idx
):
	'''
	check input when cliked
	show enemy information when right clicked
	check collision information when left clicked
	'''
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and !GameStateManager.is_dialog_active():
			if event.pressed:
				print("Enemy took 20 damage")
				enemy.hp -= 20
				print("Enemy currently has ", enemy.hp, "HP")
