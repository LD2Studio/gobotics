extends ConfirmationDialog


func _ready() -> void:
	get_ok_button().disabled = true


func _on_project_name_edit_text_changed(new_text: String) -> void:
	if new_text == "":
		get_ok_button().disabled = true
	else:
		get_ok_button().disabled = false
