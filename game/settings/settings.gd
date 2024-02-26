extends Control

@onready var asset_path_edit: LineEdit = %AssetPathEdit
@onready var project_path_edit: LineEdit = %ProjectPathEdit
@onready var add_mods_dialog: FileDialog = %AddModsDialog
@onready var mods_list: ItemList = %ModsList

func _ready() -> void:
	show_settings()
	
	
func show_settings() -> void:
	asset_path_edit.text = GSettings.asset_path
	project_path_edit.text = GSettings.project_path
	_update_mods_list()


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


func _on_add_mods_button_pressed() -> void:
	add_mods_dialog.popup_centered()


func _on_add_mods_dialog_file_selected(path: String) -> void:
	#print("mod: ", path)
	_load_mod(path)


func _load_mod(path: String):
	var success = ProjectSettings.load_resource_pack(path, false)
	if not success:
		printerr("Failed to loading modules!")
	else:
		GSettings.settings_db.mod_paths.append(path)
		GSettings.save_settings()
		_update_mods_list()


func _update_mods_list():
	mods_list.clear()
	
	for mod_path in GSettings.settings_db.mod_paths:
		mods_list.add_item(mod_path)
