#extends Item
#class_name DifferentialRobot
#
#@export var speed: float = 5.0
#@export_flags_3d_physics var collision_groups = 1
#@onready var robot := Robot.new()
#@onready var target := Target.new()
#
#enum {
#	idle,
#	line_control,
#	orientation_control,
#}
#
#class Robot:
#	var frame: RigidBody3D
#	var right_wheel
#	var left_wheel
#	var speed: float
#	var state: int
#	var task_finished: bool = true
#	var manual_control: bool = true
#
#class Target:
#	var pos: Vector2 # Position de la cîble dans le plan XZ
#	var orientation: float	# Orientation par rapport à l'axe -Z
#
#func _enter_tree():
#	add_to_group("PYTHON")
#	add_to_group("ROBOT")
#
#func init(right_wheel = null, left_wheel = null):
#	super()
##	add_child(python)
#	var frame = get_child(0)
#	assert(frame is RigidBody3D, "Frame robot must be RigidBody3D type")
#	assert(right_wheel != null, "Right Wheel is not defined!")
#	assert(left_wheel != null, "Left Wheel is not defined!")
#	robot.frame = frame
#	robot.right_wheel = right_wheel
#	robot.left_wheel = left_wheel
#	set_meta("manual_control", true)
#	frame.freeze = true
#	frame.collision_mask = collision_groups
#	for child in frame.get_children():
#		if child is RigidBody3D:
#			child.collision_mask = collision_groups
#
#func update_input():
#	if not python.activate and robot.manual_control:
#		if Input.is_action_pressed("FORWARD"):
#			if Input.is_action_pressed("RIGHT"):
#				robot.right_wheel.rotation_speed = 0
#			else:
#				robot.right_wheel.rotation_speed = speed
#			if Input.is_action_pressed("LEFT"):
#				robot.left_wheel.rotation_speed = 0
#			else:
#				robot.left_wheel.rotation_speed = speed
#		elif Input.is_action_pressed("BACKWARD"):
#			robot.right_wheel.rotation_speed = -speed
#			robot.left_wheel.rotation_speed = -speed
#		elif Input.is_action_pressed("RIGHT"):
#			robot.right_wheel.rotation_speed = -speed
#			robot.left_wheel.rotation_speed = speed
#		elif Input.is_action_pressed("LEFT"):
#			robot.right_wheel.rotation_speed = speed
#			robot.left_wheel.rotation_speed = -speed
#		else:
#			robot.right_wheel.rotation_speed = 0
#			robot.left_wheel.rotation_speed = 0
#
#func update_process(_delta) -> void:
##	if not running:
##		robot.state = idle
##		robot.task_finished = true
#	match robot.state:
#		line_control:
#			var pos: Vector2 = Vector2(robot.frame.global_position.x/10.0, robot.frame.global_position.z/10.0)
#			var d_square = pow((target.pos.x - pos.x), 2) + pow((target.pos.y - pos.y), 2)
##			print(d_square)
#			const d_square_threshold = 0.01**2
#			if d_square > d_square_threshold:
#				var forward_dir : Vector3 = -robot.frame.global_transform.basis.z
#				var dir := Vector2(forward_dir.x, forward_dir.z)
##				var vec_to_target: Vector2 = target.pos - pos
#				var err_theta: float = -dir.angle_to(target.pos - pos)
##				print("dir: ", dir)
##				print("err_theta: ", rad_to_deg(err_theta))
##				var theta: float = robot.frame.global_rotation.y
##				print("theta: ", rad_to_deg(theta))
##				var theta_m: float = atan2(-target.pos.x + pos.x, -target.pos.y + pos.y)
##				print("theta_m: ", rad_to_deg(theta_m))
##				var err_theta: float = theta_m - theta
#				const Kp = 20.0
#				const MAX_SPEED = 7
#				var omega_c: float = Kp * err_theta
#				move(clampf(robot.speed + omega_c, -MAX_SPEED, MAX_SPEED),
#					clampf(robot.speed - omega_c, -MAX_SPEED, MAX_SPEED))
#			else:
#				move(0,0)
#				robot.state = orientation_control
#
#		orientation_control:
##			print("orientation control")
#			var forward_dir : Vector3 = -robot.frame.global_transform.basis.z
#			var dir := Vector2(forward_dir.x, forward_dir.z)
#			var target_dir := Vector2.from_angle(-target.orientation - PI/2)
##			print("target_dir: ", target_dir)
#			var err_theta: float = -dir.angle_to(target_dir)
##			print("err_theta", err_theta)
##			var theta: float = robot.frame.global_rotation.y
#			const theta_th = deg_to_rad(1)
##			var err_theta: float = target.orientation - theta
#			if abs(err_theta) > theta_th:
#				const Kp = 7.0
#				const MAX_SPEED = 7
#				var omega_c: float = Kp * err_theta
#				omega_c = clampf(omega_c, -MAX_SPEED, MAX_SPEED)
##				print(omega_c)
#				move(omega_c, -omega_c)
#			else:
#				move(0,0)
#				robot.state = idle
#				robot.task_finished = true
#
### Functions calling by Python
#func set_pose(x: float, z: float, a: float):
#	robot.frame.global_position.x = x * 10.0
#	robot.frame.global_position.z = z * 10.0
#	robot.frame.rotation.y = a
#
#func get_pose() -> Vector3:
#	var pose = Vector3(
#		robot.frame.global_position.x / 10.0,
#		robot.frame.global_position.z / 10.0,
#		robot.frame.rotation.y)
#	return pose
#
#func move(right_vel: float, left_vel: float):
#	robot.right_wheel.rotation_speed = right_vel
#	robot.left_wheel.rotation_speed = left_vel
#
#func move_to(new_pose: Vector3, new_speed: float):
##	print("Move to (%f, %f)" % [new_pose.x, new_pose.y])
#	target.pos = Vector2(new_pose.x, new_pose.y)
#	target.orientation = new_pose.z
#	robot.speed = new_speed
#	robot.state = line_control
#	robot.task_finished = false
#
#func task_finished() -> bool:
#	return robot.task_finished
