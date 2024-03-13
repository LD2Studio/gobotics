extends Node3D


@export var activate: bool = false:
	set(value):
		activate = value
		if is_instance_valid(force_area):
			force_area.visible = true if activate else false

@export var magnet_radius: float = 0.01:
	set(new_radius):
		magnet_radius = new_radius
		if is_instance_valid(support):
			var mesh: CylinderMesh = support.mesh
			mesh.top_radius = magnet_radius * GPSettings.SCALE
			mesh.bottom_radius = magnet_radius * GPSettings.SCALE

@onready var support: MeshInstance3D = $Support
@onready var force_area: MeshInstance3D = $Support/ForceArea


func set_physics(enable: bool):
	pass
	#print("[%s] physics: %s" % [name, enable])
	
