extends Node

signal dialog_started
signal dialog_line_changed(line: DialogLine)
signal dialog_finished
signal dialog_target_changed(target: Node3D)

signal auto_advance_request

var camera: CameraController

var lines: Array[DialogLine] = []
var active := false
var current_index := 0
var current_target: Node3D

var auto_mode := false
var paused := false

@export var auto_delay := 5.0

var auto_timer := 0.0

func _process(delta: float) -> void:
	if !active or !auto_mode:
		return
		
	auto_timer += delta
	
	if auto_timer >= auto_delay:
		auto_timer = 0.0
		auto_advance_request.emit()

func register_camera(cam: CameraController) -> void:
	if camera != null and camera != cam:
		push_warning("DialogManager already has a camera registered.")
	camera = cam

func start_dialog(new_lines: Array[DialogLine]) -> void:
	print("Start dialog was called in DialogManager")
	if active:
		print("DialogManager active state: ", active)
		return
		
	if new_lines.is_empty():
		print("DialogManager recieved no dialog lines, halting")
		return
		
	lines = new_lines
	current_index = 0
	auto_timer = 0.0
	active = true
	
	GameStateManager.enter_dialog()
	
	dialog_started.emit()
	
	_show_current_line()
	
func auto_debug():
	await get_tree().create_timer(5.0).timeout
	
func _show_current_line() -> void:
	print("===SHOW CURRENT LINE===")
	print("Total lines: ", lines.size())
	print("Current index: ", current_index)
	
	
	
	if current_index >= lines.size():
		finish_dialog()
		return
	
	print("line size: ", lines.size())
	auto_timer = 0.0
	
	var line := lines[current_index]
	current_target = line.target
	
	dialog_line_changed.emit(line)
	dialog_target_changed.emit(line.target)
	
	if line.target and camera:
		print(line.target)
		camera.focus_on(line.target, Vector3.ZERO)
		
func advance_dialog() -> void:
	if !active:
		return
	
	current_index += 1
	_show_current_line()
		
func finish_dialog() -> void:
	if !active:
		return
		
	active = false
	lines.clear()
	current_target = null
	
	if camera:
		camera.release_focus()
	
	dialog_finished.emit()
	dialog_target_changed.emit(null)
	
	GameStateManager.exit_dialog()
	
