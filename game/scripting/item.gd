#extends Node3D
#class_name Item
#
#signal python_script_finished(text: String)
#
#@onready var python = PythonBridge.new(4243)
#@export_multiline var source_code: String
#
#var python_thread: Thread = Thread.new()
#
#var _rigid_node: RigidBody3D
#var running: bool
#var builtin: bool = false
#
#func _enter_tree():
#	add_to_group("PYTHON")
#
#func _process(_delta: float) -> void:
#	pass
##	if python_thread:
##		if not python_thread.is_alive():
##			print("thread not alive...")
#
#func init():
#	add_child(python)
#	assert(get_child(0) is RigidBody3D, "This items is not physics")
#	_rigid_node = get_child(0)
#
#func run():
#	running = true
#	if not builtin or not python.activate: return
#	if python_thread and python_thread.is_started(): return
##	print("Start new Python thread")
#	if python_thread.start(_run_python_script.bind(source_code)) != OK:
#		printerr("Thread not starting...")
#
#func stop():
#	running = false
#
#func _run_python_script(code):
#	var script_path = ProjectSettings.globalize_path("res://python/interactive.py")
#	var output: Array
#	OS.execute("python", [script_path, code], output, true)
##	print(output)
#	call_deferred("ending_run_script")
#	return output[0]
#
#func ending_run_script():
#	var res = python_thread.wait_to_finish()
##	print("Thread finished: ", res)
#	python_script_finished.emit(res)
#
#func is_running() -> bool:
#	return running
#
#func get_pos() -> Vector3:
#	return _rigid_node.global_position/10.0
#
#func set_pos(value: Vector3):
#	_rigid_node.global_position = value*10.0
