extends ItemList

const project_scene_path = "res://game/project/game.tscn"

func _ready() -> void:
	%ProjectMenu.visible = false
	var scroll_bar = get_v_scroll_bar()
	scroll_bar.scrolling.connect(_on_resized)
	show_projects_in_list()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_UP:
			#print("event: ", event)
			_on_resized()
			
	if event is InputEventKey:
		if event.keycode == KEY_DELETE and event.pressed:
			_on_delete_button_pressed()


func _on_item_selected(index: int) -> void:
	var rect_item: Rect2 = get_item_rect(index)
	#print("rect item: ", rect_item)
	var scroll_value: float = get_v_scroll_bar().value
	%ProjectMenu.position = rect_item.end - %ProjectMenu.size - Vector2(20,10) - Vector2(0, scroll_value)
	%ProjectMenu.visible = true


func _on_resized() -> void:
	if item_count == 0: return
	
	if is_anything_selected():
		var selected_project_index = get_selected_items()
		var rect_item: Rect2 = get_item_rect(selected_project_index[0])
		var scroll: VScrollBar = get_v_scroll_bar()
		%ProjectMenu.position = rect_item.end - %ProjectMenu.size - Vector2(20,10) - Vector2(0, scroll.value)
		%ProjectMenu.visible = true


func show_projects_in_list():
	clear()
	for file in FileSystem.get_all_project_names():
		add_item(file, preload("res://gobotics_logo.png"))


func _on_load_button_pressed() -> void:
	var selected_project_index = get_selected_items()
	if selected_project_index.is_empty(): return
	var project_file = get_item_text(selected_project_index[0]) + ".scene"

	GPSettings.project_filename = project_file
	GPSettings.is_new_project = false
	var err = get_tree().change_scene_to_file(project_scene_path)
	if err != OK:
		printerr("Changing scene failed")


func _on_item_activated(_index: int) -> void:
	_on_load_button_pressed()


func _on_delete_button_pressed() -> void:
	var selected_project_index = get_selected_items()
	if selected_project_index.is_empty(): return
	%DeleteProjectDialog.popup_centered()


func _on_delete_project_dialog_confirmed() -> void:
	var selected_project_index = get_selected_items()
	if selected_project_index.is_empty(): return
	
	var project_file = get_item_text(selected_project_index[0]) + ".scene"
	
	DirAccess.remove_absolute(GSettings.project_path.path_join(project_file))
	show_projects_in_list()

func _on_rename_button_pressed() -> void:
	var selected_project_index = get_selected_items()
	if selected_project_index.is_empty(): return
	var project_name = get_item_text(selected_project_index[0])
	
	%RenameProjectDialog.get_node("ProjectNameEdit").text = project_name
	%RenameProjectDialog.popup_centered()


func _on_rename_project_dialog_confirmed() -> void:
	var new_project_file = ( GSettings.project_path
			.path_join(%RenameProjectDialog.get_node("ProjectNameEdit").text + ".scene"))
	
	var selected_project_index = get_selected_items()
	if selected_project_index.is_empty(): return
	var current_project_file = ( GSettings.project_path
			.path_join(get_item_text(selected_project_index[0]) + ".scene"))
	
	DirAccess.rename_absolute(current_project_file, new_project_file)
	show_projects_in_list()


func _on_duplicate_button_pressed() -> void:
	var selected_project_index = get_selected_items()
	if selected_project_index.is_empty(): return
	var project_name = get_item_text(selected_project_index[0])
	
	$DuplicateProjectDialog/VBoxContainer/Message.text = (
		"Duplicate the \"%s\" project under the name :" % [project_name])
	$DuplicateProjectDialog/VBoxContainer/ProjectNameEdit.text = project_name
	%DuplicateProjectDialog.get_ok_button().disabled = true
	%DuplicateProjectDialog.popup_centered()


func _on_project_name_edit_text_changed(new_project_name: String) -> void:
	if new_project_name in FileSystem.get_all_project_names():
		%DuplicateProjectDialog.get_ok_button().disabled = true
	else:
		%DuplicateProjectDialog.get_ok_button().disabled = false


func _on_duplicate_project_dialog_confirmed() -> void:
	var selected_project_index = get_selected_items()
	if selected_project_index.is_empty(): return
	var project_name = get_item_text(selected_project_index[0])
	
	var duplicate_project = project_name + ".scene"
	var new_project: String = $DuplicateProjectDialog/VBoxContainer/ProjectNameEdit.text + ".scene"
	DirAccess.copy_absolute(
		GSettings.project_path.path_join(duplicate_project),
		GSettings.project_path.path_join(new_project)
	)
	show_projects_in_list()
