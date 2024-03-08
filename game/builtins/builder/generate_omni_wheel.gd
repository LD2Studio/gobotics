@tool
extends EditorScript

var wheel_name = "omni_wheel"
var rim_radius = 0.25
var rim_thickness = 0.14
var roller_count : int = 12

const SCALE = 10.0

var roller_1_shape: SphereShape3D = load("res://game/builtins/shapes/roller_005_shape.tres")
var roller_2_shape: SphereShape3D = load("res://game/builtins/shapes/roller_004_shape.tres")
var roller_mesh: SphereMesh = load("res://game/builtins/shapes/roller_005_mesh.tres")

var roller_node3d = load("res://game/builtins/shapes/roller.glb")

# Called when the script is executed (using File -> Run in Script Editor).
func _run():
	var omni_wheel: RigidBody3D = generate_omni_wheel("OmniWheel")
	if true:
		var scene := PackedScene.new()
		var err = scene.pack(omni_wheel)
		if err == OK:
			var err_saving = ResourceSaver.save(scene, "res://game/builtins/%s.tscn" % [wheel_name])
			if err_saving:
				printerr("Saving failed %d", err_saving)
		else:
			printerr("Packing failed")
			
	print("Omni wheels generated!")

func generate_omni_wheel(name: String):
	var mecanum_wheel := RigidBody3D.new()
	var rim_visual := MeshInstance3D.new()
	var shaft_visual := MeshInstance3D.new()
	var rim_collision := CollisionShape3D.new()
	
	mecanum_wheel.name = name
	mecanum_wheel.mass = 0.2
	mecanum_wheel.collision_mask = 0b0011
	# Visual
	rim_visual.name = "RimVisual"
	var rim_mesh := CylinderMesh.new()
	rim_mesh.top_radius = rim_radius; rim_mesh.bottom_radius = rim_radius; rim_mesh.height = rim_thickness
	rim_visual.mesh = rim_mesh
	rim_visual.rotate_x(deg_to_rad(90))
	mecanum_wheel.add_child(rim_visual)
	rim_visual.owner = mecanum_wheel
	shaft_visual.name = "ShaftVisual"
	var shaft_mesh := BoxMesh.new()
	shaft_mesh.size = Vector3(0.1, 0.1, 0.2)
	shaft_visual.mesh = shaft_mesh
	shaft_visual.set("surface_material_override/0", load("res://game/builtins/materials/black.tres"))
	mecanum_wheel.add_child(shaft_visual)
	shaft_visual.owner = mecanum_wheel
	# Collision
	rim_collision.name = "RimCollision"
	var rim_shape := CylinderShape3D.new()
	rim_shape.radius = rim_radius; rim_shape.height = rim_thickness
	rim_collision.shape = rim_shape
	rim_collision.rotate_x(deg_to_rad(90))
	mecanum_wheel.add_child(rim_collision)
	rim_collision.owner = mecanum_wheel
	
	var shift_rotation : float = 2*PI / roller_count
	for roller_idx in roller_count:
		
		var roller_joint := JoltHingeJoint3D.new()
		roller_joint.name = "RollerJoint%d" % [roller_idx]
		roller_joint.motor_max_torque = 0.1
		roller_joint.motor_enabled = true
		roller_joint.node_a = "../"
		roller_joint.rotate_z(roller_idx * shift_rotation)
		if roller_idx % 2 == 0:
			roller_joint.translate(Vector3(rim_radius, 0, 0.05))
		else:
			roller_joint.translate(Vector3(rim_radius, 0, -0.05))
		roller_joint.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
		mecanum_wheel.add_child(roller_joint)
		roller_joint.owner = mecanum_wheel
		
		var roller_link := RigidBody3D.new()
		roller_link.name = "RollerLink%d" % [roller_idx]
		roller_link.mass = 0.05
		roller_link.collision_mask = 0b0011
		roller_joint.node_b = "RollerLink%d" % [roller_idx]
		roller_link.physics_material_override = load("res://game/builtins/physics/roller_physics.tres")
		roller_joint.add_child(roller_link)
		roller_link.owner = mecanum_wheel
		
		var roller_col := CollisionShape3D.new()
		roller_col.name = "RollerCol"
		roller_col.shape = roller_1_shape
		roller_link.add_child(roller_col)
		roller_col.owner = mecanum_wheel
		
		var rollerR_col := CollisionShape3D.new()
		rollerR_col.name = "RollerColR"
		rollerR_col.shape = roller_2_shape
		rollerR_col.position.z = 0.074
		roller_link.add_child(rollerR_col)
		rollerR_col.owner = mecanum_wheel
		
		var rollerL_col := CollisionShape3D.new()
		rollerL_col.name = "RollerColL"
		rollerL_col.shape = roller_2_shape
		rollerL_col.position.z = -0.074
		roller_link.add_child(rollerL_col)
		rollerL_col.owner = mecanum_wheel
		
#		var roller_mesh_obj := MeshInstance3D.new()
#		roller_mesh_obj.name = "RollerMesh"
#		roller_mesh_obj.mesh = roller_mesh
#		roller_mesh_obj.rotation.x = deg_to_rad(90)
#		roller_link.add_child(roller_mesh_obj)
#		roller_mesh_obj.owner = mecanum_wheel

		var roller_instance : Node3D = roller_node3d.instantiate()
		roller_instance.name = "RollerMesh"
		roller_instance.rotation.x = deg_to_rad(90)
		roller_instance.scale *= SCALE
		roller_link.add_child(roller_instance)
		roller_instance.owner = mecanum_wheel
		
#	mecanum_wheel.print_tree_pretty()
	
	return mecanum_wheel
