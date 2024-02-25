class_name VisualMesh
extends MeshInstance3D

func highlight(asset_node):
	var mat = get_surface_override_material(0)
	if mat == null: return
	
	if owner and asset_node and owner.name == asset_node.name:
		mat.next_pass = preload("res://game/assets/outliner/outliner.tres")
	else:
		mat.next_pass = null
