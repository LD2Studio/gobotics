extends ItemList

@onready var delete_project_dialog: ConfirmationDialog = $DeleteProjectDialog
@onready var rename_project_dialog: ConfirmationDialog = $RenameProjectDialog

var icon: Texture2D = preload("res://gobotics_logo.png")
var rename_button: Button


func _ready() -> void:
	init_buttons()
	show_projects()


func init_buttons():
	rename_button = Button.new()
	rename_button.text = "Rename"
	rename_button.visible = false
	add_child(rename_button)
	rename_button.pressed.connect(rename_project)


func show_projects():
	var project_files = Array(DirAccess.get_files_at(GSettings.project_path))
	var project_names = project_files.map(func(file: String): return file.trim_suffix(".scene"))
	
	clear()
	for file in project_names:
		add_item(file, icon)


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
	
	DirAccess.remove_absolute(GSettings.project_path.path_join(project_file))
	show_projects()


func _on_item_selected(index: int) -> void:
	var rect_item: Rect2 = get_item_rect(index)
	print("rect item: ", rect_item)
	if rename_button:
		rename_button.position = rect_item.end - rename_button.size
		rename_button.visible = true


func rename_project():
	var selected_project_index = get_selected_items()
	if selected_project_index.is_empty(): return
	var project_name = get_item_text(selected_project_index[0])
	print("project name: ", project_name)
	rename_project_dialog.get_node("ProjectNameEdit").text = project_name
	rename_project_dialog.popup_centered()


func _on_rename_project_dialog_confirmed() -> void:
	var new_project_file = ( GSettings.project_path
			.path_join(rename_project_dialog.get_node("ProjectNameEdit").text + ".scene"))
	
	var selected_project_index = get_selected_items()
	if selected_project_index.is_empty(): return
	var current_project_file = ( GSettings.project_path
			.path_join(get_item_text(selected_project_index[0]) + ".scene"))
	
	DirAccess.rename_absolute(current_project_file, new_project_file)
	show_projects()
	
