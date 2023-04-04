extends PythonBridge

var process_value: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	process_value = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)
	process_value += delta

func hello():
	print("Hello from Python client")
	
func set_value(value: int):
	print("value = %d" % value)

func get_value() -> int:
	return 10
	
func get_values(number: float = 1) -> Array:
	var values: Array
	for i in number:
		values.append(process_value)
		await get_tree().process_frame
		
	return values

func get_float32(count: int = 1) -> PackedByteArray:
	var numbers: PackedFloat32Array
	
	for i in count:
		numbers.append(randf())
		
	print("numbers: ", numbers)
	var numbers_bytes: PackedByteArray
	numbers_bytes.append(0) # Header for bytes data
	numbers_bytes.append_array(numbers.to_byte_array())
	print("numbers bytes: ", numbers_bytes)
	return numbers_bytes
