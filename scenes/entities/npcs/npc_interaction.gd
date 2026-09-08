class_name Interactable
extends Area3D

@onready var player: Player = get_tree().get_first_node_in_group("player")
@export var npc: NPC

var times_hovered: int = 0
var hovered: bool = false

var test_text := "
Lorem ipsum dolor sit amet consectetur adipiscing elit. Quisque faucibus ex sapien vitae pellentesque sem placerat. In id cursus mi pretium tellus duis convallis. Tempus leo eu aenean sed diam urna tempor. Pulvinar vivamus fringilla lacus nec metus bibendum egestas. Iaculis massa nisl malesuada lacinia integer nunc posuere. Ut hendrerit semper vel class aptent taciti sociosqu. Ad litora torquent per conubia nostra inceptos himenaeos.
"

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

func _on_mouse_entered():
	set_hovered(true)
	
func _on_mouse_exited():
	set_hovered(false)
	
func set_hovered(value: bool):
	'''
	set npc name toggle when hovered and not in dialog
	'''
	hovered = value
	if hovered:
		print("Hovering NPC ")
	
	if npc:
		npc.show_name(value)
	
func _on_input_event(
	camera, event, position, normal, shape_idx
):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				player.try_to_interact(self)

func interact() -> void:
	print("====NPC INTERACT====")
	print("Interact was called")
	if GameStateManager.is_dialog_active():
		print("Game is currently in active dialog game state")
		return
	
	if CombatManager.is_in_combat():
		print("Game is currently in active combat game state")
		return
		
	start_dialog()
	
func start_dialog() -> void:
	var lines: Array[DialogLine] = [
		DialogLine.new(
			"NPC",
			"May I help you?",
			npc.focus_point
		),
		DialogLine.new(
			"Player",
			"I'll be asking the damn questions, old man. Who are you?",
			player.focus_point
		),
		DialogLine.new(
			"Yu",
			"Yu.",
			npc.focus_point
		),
		DialogLine.new(
			"Player",
			"No, not me, you.",
			player.focus_point
		),
		DialogLine.new(
			"Yu",
			"Yes, I am Yu.",
			npc.focus_point
		),
		DialogLine.new(
			"Player",
			"Just answer the damn questions, who are you?",
			player.focus_point
		),
		DialogLine.new(
			"Yu",
			"I have told you, Yu.",
			npc.focus_point
		),
		DialogLine.new(
			"Player",
			"Are you deaf?",
			player.focus_point
		),
		DialogLine.new(
			"Yu",
			"No, Yu is blind.",
			npc.focus_point
		),
		DialogLine.new(
			"Player",
			"I'm not blind, you blind.",
			player.focus_point
		),
		DialogLine.new(
			"Yu",
			"That is what I just said.",
			npc.focus_point
		),
		DialogLine.new(
			"Player",
			"You just said what?",
			player.focus_point
		),
		DialogLine.new(
			"Yu",
			"I did not say what, I said Yu!",
			npc.focus_point
		),
		DialogLine.new(
			"Player",
			"That's what I'm askin' you!",
			player.focus_point
		),
		DialogLine.new(
			"Yu",
			"And Yu is answering.",
			npc.focus_point
		),
		DialogLine.new(
			"Player",
			"And I'm about to whoop your old ass, man, 'cause I'm sick of playin' games! You, me, everybody's ass around here! I'm-a kick yo' ass, I'm sick of this bullshit!",
			player.focus_point
		),
	]
	print("NPC dialog has been loaded")
	DialogManager.start_dialog(lines)
