extends PythonBridge
class_name DifferentialRobotPythonBridge

var left_wheel: RigidBody3D
var right_wheel: RigidBody3D
var root_rigid_body: RigidBody3D

signal aligned_to_direction
signal distance_covered

const ANGLE_TH = 0.15

var _aligned: bool = false
var _aligned_with_feedback := false
var _max_speed: float
var _dir_to_target: Vector3
var _move_forward: bool = false
var _start_pos: Vector3
var _distance_to_cover: float
var _task_finished: bool = true

func _physics_process(delta):
#	print("loop")
	if _aligned:
		var current_orientation: Vector3 = -root_rigid_body.global_transform.basis.z
		if current_orientation.angle_to(_dir_to_target) < ANGLE_TH:
			_aligned = false
			aligned_to_direction.emit()
			
	if _aligned_with_feedback:
		var current_orientation: Vector3 = -root_rigid_body.global_transform.basis.z
		var angle_diff = current_orientation.angle_to(_dir_to_target)
		var side: float = root_rigid_body.global_transform.basis.x.dot(_dir_to_target)
		var wheel_vel = clampf(10.0 * angle_diff, 0, _max_speed)
#		print("mag: ", wheel_vel)
		move(-wheel_vel*sign(side), wheel_vel*sign(side))
		
	if _move_forward:
		var current_pos = root_rigid_body.global_position/10.0
		if _start_pos.distance_to(current_pos) > _distance_to_cover:
			
			_move_forward = false
			distance_covered.emit()

func move(right_vel: float, left_vel: float):
	right_wheel.rotation_speed = right_vel
	left_wheel.rotation_speed = left_vel

func move_to(target_pos: Vector3, speed: float, feedback = false):
#	print("feedback: ", feedback)
	_task_finished = false
	var current_pos = root_rigid_body.global_position/10.0
#	print("current pos: ", current_pos)
	var dir_to_target: Vector3 = current_pos.direction_to(target_pos)
#	print("dir: ", dir_to_target)
	if feedback:
		align_with_feedback(dir_to_target, speed)
		var current_orientation: Vector3 = -root_rigid_body.global_transform.basis.z
		var angle_diff = current_orientation.angle_to(dir_to_target)
		var delay = angle_diff/(0.5/(2*1.2)*(speed)) * 1.0
		print("delay: ", delay)
		await get_tree().create_timer(delay).timeout
		_aligned_with_feedback = false
	else:
		align_to(dir_to_target, speed)
		await aligned_to_direction
	print("aligned!")
	move_forward_to(target_pos, speed)
	await distance_covered
	print("distance cover!")
	move(0,0)
	_task_finished = true

func align_to(dir, speed):
#	print("align_to")
	var side: float = root_rigid_body.global_transform.basis.x.dot(dir)
	turn(side, speed)
	_aligned = true
	_dir_to_target = dir
	
func align_with_feedback(dir, speed):
	_aligned_with_feedback = true
	_dir_to_target = dir
	_max_speed = speed

func move_forward_to(target_pos, speed):
	_start_pos = root_rigid_body.global_position/10.0
	_distance_to_cover = _start_pos.distance_to(target_pos)
	move(speed, speed)
	_move_forward = true

func turn(side, speed):
	if side > 0:
#		print("turn right")
		move(-speed, speed)
	else:
#		print("turn left")
		move(speed, -speed)
