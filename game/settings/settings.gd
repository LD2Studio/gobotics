extends Control

@onready var asset_path_edit: LineEdit = %AssetPathEdit
@onready var project_path_edit: LineEdit = %ProjectPathEdit
@onready var mods_list: ItemList = %ModsList

func _ready() -> void:
	show_settings()
	
	
func show_settings() -> void:
	asset_path_edit.text = GSettings.asset_path
	project_path_edit.text = GSettings.project_path
	_update_mods_list()
	%RemoveModsButton.disabled = true


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
	%AddModsDialog.popup_centered()


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


func _on_remove_mods_button_pressed() -> void:
	var idx: int = mods_list.get_selected_items()[0]
	var module_path: String = mods_list.get_item_text(idx)
	%RemoveModsDialog.dialog_text = "Do you want to remove \"%s\" module from Gobotics?" % [module_path]
	%RemoveModsDialog.popup_centered()


func _on_mods_list_item_selected(index: int) -> void:
	%RemoveModsButton.disabled = false


func _on_remove_mods_dialog_confirmed() -> void:
	var idx: int = mods_list.get_selected_items()[0]
	var module_path: String = mods_list.get_item_text(idx)
	_remove_mod(module_path)


func _remove_mod(path: String):
	GSettings.settings_db.remove_mod(path)
	GSettings.save_settings()
	%ReloadGoboticsDialog.popup_centered()


func _on_reload_gobotics_dialog_confirmed() -> void:
	OS.set_restart_on_exit(true)
	get_tree().quit()
