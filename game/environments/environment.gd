extends Node3D

signal asset_exited(asset: Node3D)

@onready var living_area: Area3D = %LivingArea


func _ready() -> void:
	living_area.add_to_group("PHYSICS_AREA")
	living_area.body_exited.connect(_on_body_exited)


func _on_body_exited(body):
	asset_exited.emit(body)
