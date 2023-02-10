extends Control

# IMPORTANT : Mettre la propriété "mouse_filter" du noeud racine sur "Pass" pour ne pas bloquer la détection des objets physiques avec la souris

@onready var world_3d: Node3D = $SplitContainer/LevelContainer/SubViewport/World3D

var selected_block: Node

func _ready():
	world_3d.focused_block.connect(_on_selected_block)

func _on_blocks_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	pass
#	print("Item clicked")

func _on_selected_block(block: Node):
	if block == null:
		selected_block = null
		%BlockName.text = ""
		%X_pos.editable = false
		%Y_pos.value = 0
		%Z_pos.value = 0
	else:
		selected_block = block
		%BlockName.text = block.name
		%X_pos.editable = true
		%X_pos.value = block.position.x
		%Y_pos.value = block.position.y
		%Z_pos.value = block.position.z


func _on_x_pos_value_changed(value: float) -> void:
	if selected_block == null:
		return
	selected_block.position.x = value
	

func _on_save_button_pressed() -> void:
	world_3d.save_tscn()
