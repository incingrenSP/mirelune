extends Control

@onready var speaker_label: Label = $DialogBox/BoxPanel/SpeakerLabel
@onready var text_label: RichTextLabel = $DialogBox/BoxPanel/TextLabel
@onready var pause_button: Button = $Controls/Pause
@onready var log_button: Button = $Controls/Log
@onready var auto_button: Button = $Controls/Auto
@onready var dialog_log: Control = $DialogLog
@onready var log_vbox : VBoxContainer = $DialogLog/Panel/ScrollContainer/VBoxContainer

@export var pause_menu: PauseMenu

const LOG_ENTRY_SCENE := preload("res://scenes/user_interface/dialogs/dialog_log_entry.tscn")
var auto_mode_before_log := false

func _ready() -> void:
	visible = false
	speaker_label.add_theme_font_size_override("font_size", 24)
	text_label.add_theme_font_size_override("normal_font_size", 24)
	
	dialog_log.visible = false
	
	pause_button.toggle_mode = true
	log_button.toggle_mode = true
	auto_button.toggle_mode = true
	
	pause_button.toggled.connect(_on_pause_toggled)
	log_button.toggled.connect(_on_log_toggled)
	auto_button.toggled.connect(_on_auto_toggled)
	
	text_label.page_shown.connect(_add_log_entry)
	
	DialogManager.dialog_started.connect(_on_dialog_started)
	DialogManager.dialog_line_changed.connect(_on_dialog_line_changed)
	DialogManager.dialog_finished.connect(_on_dialog_finished)
	DialogManager.auto_advance_request.connect(_on_auto_advance_request)
	
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
		
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_try_advance()
	
func _try_advance() -> void:
	if DialogManager.paused:
		return
		
	if text_label.revealing:
		text_label.skip_reveal()
		return
		
	if not text_label.advance_page():
		DialogManager.advance_dialog()
		
func _on_auto_advance_request() -> void:
	_try_advance()
	
func _on_pause_toggled(toggled_on: bool) -> void:
	print("Paused button pressed")
	pause_menu.open()
	
func _on_auto_toggled(toggled_on: bool) -> void:
	print("Auto button pressed")
	DialogManager.auto_mode = toggled_on
	
func _on_log_toggled(toggled_on: bool) -> void:
	print("Log button pressed")
	dialog_log.visible = toggled_on
	$DialogBox.visible = !toggled_on
	
	if toggled_on:
		auto_mode_before_log = DialogManager.auto_mode
		auto_button.set_pressed_no_signal(false)
		DialogManager.auto_mode = false
	
	else:
		auto_button.set_pressed_no_signal(auto_mode_before_log)
		DialogManager.auto_mode = auto_mode_before_log
	
func _on_dialog_started() -> void:
	visible = true
	for child in log_vbox.get_children():
		child.queue_free()
	
func _on_dialog_line_changed(line: DialogLine) -> void:
	speaker_label.text = line.speaker
	text_label.show_text(line.text)
	
func _on_dialog_finished() -> void:
	visible = false
	
func _add_log_entry(page_text: String) -> void:
	var entry : DialogLogEntry = LOG_ENTRY_SCENE.instantiate()
	
	log_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_vbox.add_child(entry)
	entry.setup(
		speaker_label.text,
		page_text
	)
