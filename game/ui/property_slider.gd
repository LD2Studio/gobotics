class_name PropertySlider extends VBoxContainer

signal value_changed(value: float)

var h_slider : HSlider
var value_label : Label

var min_value : float = -10.0:
	set(new_value):
		min_value = new_value
		h_slider.min_value = min_value
var max_value : float = 10.0:
	set(new_value):
		max_value = new_value
		h_slider.max_value = max_value
var step : float = 1.0:
	set(new_value):
		step = new_value
		h_slider.step = step
var value : float = 1.0:
	set(new_value):
		value = new_value
		h_slider.value = value

func _ready():
	h_slider = HSlider.new()
	h_slider.min_value = -10
	h_slider.max_value = 10
	h_slider.step = 1.0
	h_slider.tick_count = 3
	h_slider.ticks_on_borders = true
	h_slider.value_changed.connect(_on_slider_value_changed)
	add_child(h_slider)
	value_label = Label.new()
	add_child(value_label)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.text = "%.2f" % [h_slider.value]

func _on_slider_value_changed(new_value: float):
	value_label.text = "%.2f" % [new_value]
	value_changed.emit(new_value)
