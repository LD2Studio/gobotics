extends ItemList

func _ready() -> void:
	load_projects()
	
	
func load_projects():
	GSettings.projects_global_path = "res://examples"
	
	var project_files = DirAccess.get_files_at(GSettings.projects_global_path)
	#print("project: ", project_files)
	
	clear()
	for file in project_files:
		add_item(file)


func _on_item_activated(index: int) -> void:
	#print("index: ", index)
	var project_file = get_item_text(index)
	#print("project file: ", project_file)
	GParam.project_file = project_file
	var err = get_tree().change_scene_to_file("res://game/game.tscn")
