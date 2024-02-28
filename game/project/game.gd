class_name Game extends Control

var gravity_enabled: bool = true

# IMPORTANT : Mettre la propriété "mouse_filter" du noeud racine sur "Pass" pour ne pas bloquer la détection des objets physiques avec la souris
@onready var game_scene = %GameScene
@onready var assets_list = %AssetList
@onready var control_camera_3d: Camera3D = %"3DView"
@onready var top_camera_2d: Camera3D = %TopView
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
	
	if GPSettings.creating_new_project:
		current_filename = GSettings.project_path.path_join(GPSettings.project_file)
		game_scene.new_scene(GPSettings.env_path)
		game_scene.save_scene(current_filename)
	else:
		current_filename = GSettings.project_path.path_join(GPSettings.project_file)
		game_scene.load_scene(current_filename)
		
	if gravity_enabled:
		PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 98)
	else:
		PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 0)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.keycode == KEY_ESCAPE and event.pressed:
		_on_button_pressed()


func _notification(what: int) -> void:
	pass
	#print("notification: ", what)
	#if what == NOTIFICATION_WM_CLOSE_REQUEST:
		#print("CLOSE REQUEST")


func load_assets_in_database():
	GSettings.database.generate()
	
func fill_assets_list():
	assets_list.clear()
	for asset in GSettings.database.assets:
		if asset.type == "builtin_env": continue
		var idx = assets_list.add_item(asset.name)
		assets_list.set_item_metadata(idx, asset.fullname)
		assets_list.set_item_tooltip(idx, asset.fullname)


func _on_button_pressed() -> void:
	game_scene.save_scene(current_filename)
	game_scene.scene.child_exiting_tree.disconnect(game_scene._on_asset_exited_scene)
	var err = get_tree().change_scene_to_file("res://game/home_page/home_page.tscn")
	if err != OK:
		printerr("Changing scene failed")
