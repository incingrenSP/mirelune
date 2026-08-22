extends Area3D

@export var player: Player

var times_hovered: int = 0
var hovered: bool = false

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

func _on_mouse_entered():
	set_hovered(true)
	
func _on_mouse_exited():
	set_hovered(false)
	
func set_hovered(value: bool):
	hovered = value
		
	if player:
		player.is_hovered = value
		player.resource_bar_visibility()
	
func _on_input_event(
	camera, event, position, normal, shape_idx
):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print(">>>> PLAYER CLICKED")
			player.request_pause()
				
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				print("10 damage taken")
				player.hp -= 40
				print("Player currently has ", player.hp, "HP")
