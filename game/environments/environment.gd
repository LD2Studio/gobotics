extends Node3D

signal asset_exited(asset: Node3D)

@onready var living_area: Area3D = %LivingArea


func _ready() -> void:
	living_area.add_to_group("PHYSICS_AREA")
	living_area.body_exited.connect(_on_body_exited)
	for visual_node in get_tree().get_nodes_in_group("VISUAL"):
		if visual_node.owner == self:
			var mat: BaseMaterial3D = visual_node.get_surface_override_material(0)
			if mat:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func _on_body_exited(body):
	asset_exited.emit(body)
