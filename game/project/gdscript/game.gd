class_name Game extends Control

var gravity_enabled: bool = true

# IMPORTANT : Mettre la propriété "mouse_filter" du noeud racine sur "Pass" pour ne pas bloquer la détection des objets physiques avec la souris
@onready var game_scene = %GameScene
@onready var assets_list = %AssetList
@onready var control_camera_3d: Camera3D = %"3DView"
@onready var top_camera_2d: Camera3D = %TopView
@onready var confirm_delete_dialog: ConfirmationDialog = %ConfirmDeleteDialog
@onready var project_name: Label = %ProjectName


func _ready():
	var app_name: String = ProjectSettings.get_setting("application/config/name")
	var version: String = ProjectSettings.get_setting("application/config/version")
	%TitleApp.text = "%s v%s" % [app_name, version]
	
	assets_list.update_assets_list()
	project_name.text = "%s" % [GPSettings.project_filename.get_basename()]
		
	if GPSettings.is_new_project:
		game_scene.new_scene(GPSettings.env_path)
		game_scene.save_project()
	else:
		game_scene.load_scene(GSettings.project_path.path_join(GPSettings.project_filename))
		
	if gravity_enabled:
		PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 98)
	else:
		PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 0)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.keycode == KEY_ESCAPE and event.pressed:
		_on_button_pressed()


#func _notification(what: int) -> void:
	#pass
	#print("notification: ", what)
	#if what == NOTIFICATION_WM_CLOSE_REQUEST:
		#print("CLOSE REQUEST")


func load_assets_in_database():
	GSettings.database.generate()


func _on_button_pressed() -> void:
	var err = get_tree().change_scene_to_file("res://game/home_page/home_page.tscn")
	if err != OK:
		printerr("Changing scene failed")
