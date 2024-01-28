extends Button

@onready var environment_list: ItemList = %EnvironmentList
@onready var new_game_dialog: ConfirmationDialog = $NewGameDialog
@onready var project_name_edit = %ProjectNameEdit

func _on_pressed() -> void:
	environment_list.update_list()
	new_game_dialog.popup_centered(Vector2i(200, 300))


func _on_new_game_dialog_confirmed():
	var items = environment_list.get_selected_items()
	if items.is_empty(): return
	if project_name_edit.text.is_empty(): return
	
	var idx = items[0] # First selected item
	var env_path = environment_list.get_item_metadata(idx)
	#print("env: ", env_path)
	GParam.project_file = project_name_edit.text + ".scene"
	GParam.env_path = env_path
	GParam.creating_new_project = true
	var err = get_tree().change_scene_to_file("res://game/game.tscn")
	if err != OK:
		printerr("Changing scene failed")
