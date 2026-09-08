class_name DialogLogEntry
extends PanelContainer

@onready var speaker_label: Label = $MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label: Label = $MarginContainer/VBoxContainer/TextLabel
@onready var entry_vbox: VBoxContainer = $MarginContainer/VBoxContainer

var speaker: String:
	set(value):
		speaker = value
		if is_node_ready():
			speaker_label.text = value
			
var dialog: String:
	set(value):
		dialog = value
		if is_node_ready():
			text_label.text = value
			
func setup(p_speaker: String, p_dialog: String) -> void:
	speaker_label.text = p_speaker
	text_label.text = p_dialog
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	entry_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
