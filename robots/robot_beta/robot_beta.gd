class_name RobotBeta
extends RigidBody3D

@export var R_angular_vel: float = 5
@export var L_angular_vel: float = 5
## UDP Port number
@export_range(1024, 65535, 1) var UDP_port: int = 4242:
	set(value):
		UDP_port = value
		if get_node_or_null("%RemotePython"):
			listen_on_UDP(UDP_port)

var frozen: bool:
	set(value):
		frozen = value
		if frozen:
			freeze = true
			set_physics_process(false)
			for child in get_children():
				if child is RigidBody3D:
					child.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			freeze = false
			set_physics_process(true)
			for child in get_children():
				if child is RigidBody3D:
					child.process_mode = Node.PROCESS_MODE_INHERIT

var focused: bool
var joystick_enable: bool
var table_xy_coord: Node3D

func _ready() -> void:
	add_to_group("BLOCKS")
	add_to_group("ROBOTS")
	frozen = true
	%PickArea.mouse_entered.connect(_on_mouse_entered)
	%PickArea.mouse_exited.connect(_on_mouse_exited)
	if get_tree().get_nodes_in_group("TABLE").size() != 0:
		table_xy_coord = get_tree().get_nodes_in_group("TABLE")[0].get_node("Coord3D")
	listen_on_UDP(UDP_port)
		
func _physics_process(delta: float) -> void:
	if not %ConnectLight.enable:
		if Input.is_action_pressed("FORWARD"):
			%RightMotor.desired_velocity = R_angular_vel
			%LeftMotor.desired_velocity = L_angular_vel
		elif Input.is_action_pressed("BACKWARD"):
			%RightMotor.desired_velocity = -R_angular_vel
			%LeftMotor.desired_velocity = -L_angular_vel
		elif Input.is_action_pressed("RIGHT"):
			%RightMotor.desired_velocity = -R_angular_vel
			%LeftMotor.desired_velocity = L_angular_vel
		elif Input.is_action_pressed("LEFT"):
			%RightMotor.desired_velocity = R_angular_vel
			%LeftMotor.desired_velocity = -L_angular_vel
		else:
			%RightMotor.desired_velocity = 0
			%LeftMotor.desired_velocity = 0

func _on_mouse_entered() -> void:
	if not frozen: return
	if get_node_or_null("%Outline"):
		%Outline.visible = true
	focused = true

func _on_mouse_exited() -> void:
	if not frozen: return
	if get_node_or_null("%Outline"):
		%Outline.visible = false
	focused = false

func get_xy_pos() -> Vector2:
	var xyz_pos = global_position * table_xy_coord.transform
	var xy_pos := Vector2(xyz_pos.x, xyz_pos.y)/10
	return xy_pos
	
func get_xy_dir() -> Vector2:
#	print_debug("global basis: ", global_transform.basis)
	var xyz_basis = global_transform.basis * table_xy_coord.transform.basis
#	print_debug("xyz_basis: ", xyz_basis)
	var xy_dir:= Vector2(xyz_basis.y.x, -xyz_basis.y.z)
	return xy_dir
	
func get_localisation() -> PackedFloat32Array:
	var robot_local_tr: Transform3D = table_xy_coord.global_transform.inverse() * global_transform

	var xy_pos := Vector2(robot_local_tr.origin.x, robot_local_tr.origin.y)/10
	var angle: float = global_rotation.y
#	print([xy_pos.x, xy_pos.y, angle])
	return PackedFloat32Array([xy_pos.x, xy_pos.y, angle])
	
func listen_on_UDP(port: int):
	%PythonControl.activate(port)
