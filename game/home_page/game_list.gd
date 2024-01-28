extends ItemList

@onready var delete_project_dialog: ConfirmationDialog = $DeleteProjectDialog

func _ready() -> void:
	show_projects()


func show_projects():
	var project_files = Array(DirAccess.get_files_at(GSettings.projects_global_path))
	#print("project: ", project_files)
	var project_names = project_files.map(func(file: String): return file.trim_suffix(".scene"))
	#print("project names: ", project_names)
	
	clear()
	for file in project_names:
		add_item(file)


func _on_item_activated(index: int) -> void:
	#print("index: ", index)
	var project_file = get_item_text(index) + ".scene"
	GParam.project_file = project_file
	GParam.creating_new_project = false
	var err = get_tree().change_scene_to_file("res://game/game.tscn")
	if err != OK:
		printerr("Changing scene failed")


func _on_gui_input(event: InputEvent) -> void:
	
	if event is InputEventKey:
		if event.keycode == KEY_DELETE and event.pressed:
			var selected_project_index = get_selected_items()
			if selected_project_index.is_empty(): return
			var project_file = get_item_text(selected_project_index[0])
			delete_project_dialog.popup_centered()


func _on_delete_project_dialog_confirmed() -> void:
	var selected_project_index = get_selected_items()
	if selected_project_index.is_empty(): return
	
	var project_file = get_item_text(selected_project_index[0]) + ".scene"
	var project_path = (
			ProjectSettings.globalize_path(GSettings.projects_global_path)
			if OS.has_feature("editor")
			else OS.get_executable_path().get_base_dir().path_join(GSettings.projects_export_path))
	#print("project path: ", project_path)
	
	DirAccess.remove_absolute(project_path.path_join(project_file))
	show_projects()
