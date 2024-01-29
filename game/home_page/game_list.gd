extends ItemList

@onready var delete_project_dialog: ConfirmationDialog = $DeleteProjectDialog
@onready var rename_project_dialog: ConfirmationDialog = $RenameProjectDialog

var icon: Texture2D = preload("res://gobotics_logo.png")
var buttons_container: VBoxContainer
const project_scene_path = "res://game/project/game.tscn"

func _ready() -> void:
	add_buttons_to_item()
	show_projects_in_list()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_UP:
			#print("event: ", event)
			_on_resized()
			
	if event is InputEventKey:
		if event.keycode == KEY_DELETE and event.pressed:
			delete_project()


func _on_item_selected(index: int) -> void:
	var rect_item: Rect2 = get_item_rect(index)
	#print("rect item: ", rect_item)
	if buttons_container:
		var scroll_value: float = get_v_scroll_bar().value
		buttons_container.position = rect_item.end - buttons_container.size - Vector2(20,10) - Vector2(0, scroll_value)
		buttons_container.visible = true


func _on_resized() -> void:
	if item_count == 0: return
	
	if buttons_container and is_anything_selected():
		var selected_project_index = get_selected_items()
		var rect_item: Rect2 = get_item_rect(selected_project_index[0])
		var scroll: VScrollBar = get_v_scroll_bar()
		buttons_container.position = rect_item.end - buttons_container.size - Vector2(20,10) - Vector2(0, scroll.value)
		buttons_container.visible = true


func add_buttons_to_item():
	buttons_container = VBoxContainer.new()
	buttons_container.visible = false
	
	var load_button = Button.new()
	load_button.text = "Load"
	buttons_container.add_child(load_button)
	load_button.pressed.connect(load_project)
	
	var rename_button = Button.new()
	rename_button.text = "Rename"
	buttons_container.add_child(rename_button)
	rename_button.pressed.connect(rename_project)
	
	var delete_button = Button.new()
	delete_button.text = "Delete"
	buttons_container.add_child(delete_button)
	delete_button.pressed.connect(delete_project)
	add_child(buttons_container)
	
	var scrool_bar = get_v_scroll_bar()
	scrool_bar.scrolling.connect(_on_resized)


func show_projects_in_list():
	if not DirAccess.dir_exists_absolute(GSettings.project_path):
		DirAccess.make_dir_absolute(GSettings.project_path)
	var project_files = Array(DirAccess.get_files_at(GSettings.project_path))
	var project_names = project_files.map(func(file: String): return file.trim_suffix(".scene"))
	
	clear()
	for file in project_names:
		add_item(file, icon)


func load_project():
	var selected_project_index = get_selected_items()
	if selected_project_index.is_empty(): return
	var project_file = get_item_text(selected_project_index[0]) + ".scene"

	GParam.project_file = project_file
	GParam.creating_new_project = false
	var err = get_tree().change_scene_to_file(project_scene_path)
	if err != OK:
		printerr("Changing scene failed")


func _on_item_activated(index: int) -> void:
	load_project()


func delete_project():
	var selected_project_index = get_selected_items()
	if selected_project_index.is_empty(): return
	var project_file = get_item_text(selected_project_index[0])
	delete_project_dialog.popup_centered()


func _on_delete_project_dialog_confirmed() -> void:
	var selected_project_index = get_selected_items()
	if selected_project_index.is_empty(): return
	
	var project_file = get_item_text(selected_project_index[0]) + ".scene"
	
	DirAccess.remove_absolute(GSettings.project_path.path_join(project_file))
	show_projects_in_list()


func rename_project():
	var selected_project_index = get_selected_items()
	if selected_project_index.is_empty(): return
	var project_name = get_item_text(selected_project_index[0])
	
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
	show_projects_in_list()

