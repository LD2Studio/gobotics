extends Button

@onready var environment_list: ItemList = %EnvironmentList
@onready var new_game_dialog: ConfirmationDialog = $NewGameDialog

func _on_pressed() -> void:
	environment_list.update_list()
	new_game_dialog.popup_centered(Vector2i(200, 300))
