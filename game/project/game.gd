class_name Game extends Control

var asset_base_dir: String # Full pathname
var gravity_enabled: bool = true

var builtin_env = [
	{ name = "DarkEnv", scene_filename = "res://game/environments/dark_environment.tscn"},
	{ name = "LightEnv", scene_filename = "res://game/environments/light_environment.tscn"},
]

# IMPORTANT : Mettre la propriété "mouse_filter" du noeud racine sur "Pass" pour ne pas bloquer la détection des objets physiques avec la souris
@onready var game_scene = %GameScene
@onready var assets_list = %AssetList
@onready var control_camera_3d: Camera3D = %"3DView"
@onready var top_camera_2d: Camera3D = %TopView
@onready var object_inspector = %ObjectInspector
@onready var confirm_delete_dialog: ConfirmationDialog = %ConfirmDeleteDialog
@onready var project_name: Label = %ProjectName


var current_filename: String:
	set(value):
		current_filename = value
		project_name.text = "%s" % [current_filename.get_file().get_basename()]


func _ready():
	var app_name: String = ProjectSettings.get_setting("application/config/name")
	var version: String = ProjectSettings.get_setting("application/config/version")
	%TitleApp.text = "%s v%s" % [app_name, version]
	
	fill_assets_list()
	object_inspector.visible = false
	
	if GParam.creating_new_project:
		current_filename = GSettings.project_path.path_join(GParam.project_file)
		game_scene.new_scene(GParam.env_path)
		game_scene.save_scene(current_filename)
	else:
		current_filename = GSettings.project_path.path_join(GParam.project_file)
		game_scene.load_scene(current_filename)
		
	if gravity_enabled:
		PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 98)
	else:
		PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 0)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.keycode == KEY_ESCAPE and event.pressed:
		game_scene.save_scene(current_filename)
		var err = get_tree().change_scene_to_file("res://game/home_page/home_page.tscn")


func _on_clear_button_pressed() -> void:
	%TerminalOutput.text = ""


func load_assets_in_database():
	GSettings.database.generate(asset_base_dir, builtin_env)
	
func fill_assets_list():
	assets_list.clear()
	for asset in GSettings.database.assets:
		if asset.type == "builtin_env": continue
		var idx = assets_list.add_item(asset.name)
		assets_list.set_item_metadata(idx, asset.fullname)
		assets_list.set_item_tooltip(idx, asset.fullname)
