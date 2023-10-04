@tool
class_name URDFImporter
extends EditorImportPlugin

enum Presets {
	DEFAULT,
}

func _get_importer_name() -> String:
	return "urdf.importer"
	
func _get_visible_name() -> String:
	return "Scene"
	
func _get_recognized_extensions() -> PackedStringArray:
	return ["urdf"]
	
func _get_save_extension() -> String:
	return "tscn"

func _get_resource_type() -> String:
	return "PackedScene"
	
func _get_preset_count() -> int:
	return Presets.size()
	
func _get_preset_name(preset_index: int) -> String:
	match preset_index:
		Presets.DEFAULT:
			return "Default"
		_:
			return "Unknown"

func _get_import_options(opt: String, preset: int) -> Array[Dictionary]:
	return [
		{"name": "switch_yz", "default_value": false},
		{"name": "scale", "default_value": 1.0},
	]

func _get_import_order() -> int:
	return 0
	
func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _get_priority() -> float:
	return 1.0

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> Error:
#	print("Importing URDF file: ", source_file)
#	print_debug(options)
	
	var urdf_parser = URDFParser.new()
	urdf_parser.scale = options.scale
#	var root_node = urdf_parser.parse(source_file)

	# Save the imported scene as a PackedScene resource
	var packed_scene = PackedScene.new()
#	packed_scene.pack(root_node)
	var p = save_path + "." + _get_save_extension()
	
	return ResourceSaver.save(packed_scene, p)
