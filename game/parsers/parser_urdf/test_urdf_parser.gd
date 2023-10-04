extends Node3D

@export_file("*.urdf") var urdf_file: String

var urdf_parser = URDFParser.new()


func _ready() -> void:
	if urdf_file == "":
		print("No URDF file")
		return
	urdf_parser.scale = 10.0
#	var root_node: Node3D = urdf_parser.parse(urdf_file)
##	root_node.print_tree_pretty()
#
#	var scene := PackedScene.new()
#	var result = scene.pack(root_node)
#	if result == OK:
#		var tscn_file: String = urdf_file.get_basename() + ".tscn"
#		var error = ResourceSaver.save(scene, tscn_file)
#		if error != OK:
#			push_error("An error occurred while saving the scene to disk.")

