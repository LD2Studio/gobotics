extends RobotsPythonBridge
class_name DifferentialRobotPythonBridge

var left_wheel: RigidBody3D
var right_wheel: RigidBody3D

signal aligned_to_direction
signal distance_covered

const ANGLE_TH = 0.15

var _aligned: bool = false
var _dir_to_target: Vector3
var _move_forward: bool = false
var _start_pos: Vector3
var _distance_to_cover: float
var _task_finished: bool = false

func _physics_process(delta):
#	print("loop")
	if _aligned:
		var current_orientation: Vector3 = -root_rigid_body.global_transform.basis.z
#		var angle: float = current_orientation.angle_to(_dir_to_target)
		if current_orientation.angle_to(_dir_to_target) < ANGLE_TH:
			print("aligned!")
			_aligned = false
			aligned_to_direction.emit()
			
	if _move_forward:
		var current_pos = root_rigid_body.global_position/10.0
		if _start_pos.distance_to(current_pos) > _distance_to_cover:
			print("distance cover!")
			_move_forward = false
			distance_covered.emit()
	

func move(right_vel: float, left_vel: float):
	right_wheel.rotation_speed = right_vel
	left_wheel.rotation_speed = left_vel

func move_to(target_pos: Vector3, speed: float):
	_task_finished = false
	var current_pos = root_rigid_body.global_position/10.0
#	print("current pos: ", current_pos)
	var dir_to_target: Vector3 = current_pos.direction_to(target_pos)
#	print("dir: ", dir_to_target)

	align_to(dir_to_target, speed)
	await aligned_to_direction
	move_forward_to(target_pos, speed)
	await distance_covered
	
#	await get_tree().create_timer(4).timeout
	move(0,0)
	_task_finished = true
	
func task_finished() -> bool:
	return _task_finished
	
func align_to(dir, speed):
#	print("align_to")
	var side: float = root_rigid_body.global_transform.basis.x.dot(dir)
	turn(side, speed)
	_aligned = true
	_dir_to_target = dir

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
