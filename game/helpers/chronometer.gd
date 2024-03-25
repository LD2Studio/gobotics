class_name ChronoMeter extends RefCounted

var elapsed_time: float: get = get_elapsed_time
var _start_time_ms: int
var _elapsed_time_ms: int
var _paused: bool

func _init():
	_paused = true
	_elapsed_time_ms = 0


func start(paused: bool = true):
	_paused = paused
	_elapsed_time_ms = 0
	_start_time_ms = 0


func pause():
	_paused = true


func resume():
	_paused = false
	_start_time_ms = Time.get_ticks_msec() - _elapsed_time_ms


func get_elapsed_time() -> float:
	if _paused:
		return float(_elapsed_time_ms) / 1000.0
	else:
		_elapsed_time_ms = Time.get_ticks_msec() - _start_time_ms
		return float(_elapsed_time_ms) / 1000.0
