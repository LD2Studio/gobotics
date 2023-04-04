@tool
extends EditorPlugin


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_custom_type("RotationActuator3D", "RigidBody3D",
			preload("res://addons/actuator3d/nodes/rotation_actuator.gd"),
			preload("res://addons/actuator3d/nodes/rotation_actuator_3d.svg"))
	add_custom_type("TranslationActuator3D", "RigidBody3D",
			preload("res://addons/actuator3d/nodes/translation_actuator.gd"),
			preload("res://addons/actuator3d/nodes/translation_actuator_3d.svg"))


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_custom_type("AngularActuator3D")
