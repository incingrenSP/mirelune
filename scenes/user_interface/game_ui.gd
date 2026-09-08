extends CanvasLayer

@export var player: Player

@onready var pause_menu: PauseMenu = $PauseMenu
@onready var dialog_ui: Control = $DialogUI

func _ready() -> void:
	pause_menu.player = player
	
	pause_menu.pause_opened.connect(_on_pause_opened)
	pause_menu.pause_closed.connect(_on_pause_closed)
	
func _on_pause_opened():
	dialog_ui.visible = false
	
func _on_pause_closed():
	dialog_ui.visible = GameStateManager.is_dialog_active()
