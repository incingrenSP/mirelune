class_name DialogLine
extends RefCounted

var speaker: String
var text: String
var target: Marker3D

func _init(
	speaker_name: String,
	dialog_text: String,
	focus_target: Marker3D = null
):
	speaker = speaker_name
	text = dialog_text
	target = focus_target
