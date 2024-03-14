extends Area3D

var activate: bool = false:
	set(value):
		activate = value
		if is_instance_valid(support):
			#print("%s activated" % [name])
			if activate:
				support.get_surface_override_material(0).albedo_color = Color.RED
				gravity = magnet_strength
				set_physics_process(true)
			else:
				support.get_surface_override_material(0).albedo_color = Color.WHITE
				gravity = 0
				set_physics_process(false)

var magnet_radius: float
var magnet_strength: float

@onready var support: MeshInstance3D = $Support
@onready var magnet_collision: CollisionShape3D = $MagnetCollision


func _ready():
	activate = false
	magnet_radius = get_meta("magnet_radius", 0.04)
	magnet_strength = get_meta("magnet_strength", 5) * GPSettings.SCALE
	set_radius(magnet_radius)
	

func _physics_process(_delta: float) -> void:
	if has_overlapping_bodies():
		#print("overlapping bodies: ", get_overlapping_bodies())
		for body in get_overlapping_bodies():
			if body is RigidBody3D:
				body.sleeping = false


func set_radius(magnet_radius):
	var mesh: CylinderMesh = support.mesh
	mesh.top_radius = magnet_radius * GPSettings.SCALE
	mesh.bottom_radius = magnet_radius * GPSettings.SCALE
	var magnet_mesh: CylinderMesh = support.get_node("MagnetArea").mesh
	magnet_mesh.top_radius = magnet_radius * GPSettings.SCALE * 0.7
	magnet_mesh.bottom_radius = magnet_radius * GPSettings.SCALE * 0.7
	var magnet_col_shape: CylinderShape3D = magnet_collision.shape
	magnet_col_shape.radius = magnet_radius * GPSettings.SCALE
	#magnet_col_shape.height = magnet_radius * GPSettings.SCALE * 2
	magnet_collision.get_node("DebugMesh").mesh = magnet_col_shape.get_debug_mesh()
