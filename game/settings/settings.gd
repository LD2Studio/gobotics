extends Control

@onready var asset_path_edit: LineEdit = %AssetPathEdit
@onready var project_path_edit: LineEdit = %ProjectPathEdit

func _ready() -> void:
	show_settings()
	
	
func show_settings() -> void:
	asset_path_edit.text = GSettings.asset_path
	project_path_edit.text = GSettings.project_path


func _on_return_button_pressed() -> void:
	var err = get_tree().change_scene_to_file("res://game/home_page/home_page.tscn")
	if err:
		printerr("[ERROR] Loading homepage scene failed!")


func _on_open_asset_folder_button_pressed() -> void:
	var err = OS.shell_show_in_file_manager(asset_path_edit.text)
	if err:
		printerr("[ERROR] Opening asset folder failed!")


func _on_open_project_folder_button_pressed() -> void:
	var err = OS.shell_show_in_file_manager(project_path_edit.text)
	if err:
		printerr("[ERROR] Opening asset folder failed!")
