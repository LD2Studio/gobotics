extends ItemList

@onready var game: Control = owner
@onready var database: GoboticsDB = owner.database
@onready var asset_popup_menu: PopupMenu = %AssetPopupMenu
var asset_editor_packed_scene = preload("res://game/asset_editor/asset_editor.tscn")

enum AssetId {
	NEW,
	EDIT,
}

var _at_position: Vector2i

func _ready() -> void:
	asset_popup_menu.add_item("New", AssetId.NEW)
	asset_popup_menu.add_item("Edit", AssetId.EDIT)
	asset_popup_menu.id_pressed.connect(_on_item_menu_select)

func _get_drag_data(at_position: Vector2):
	var idx = get_item_at_position(at_position, true)
	if idx == -1 or %GameScene.running:
		return null

	var asset_name = get_item_text(idx)
	var asset = database.get_scene(asset_name)
#	print(asset)
	if asset:
		var _asset_res = load(asset)
#		print(asset_res)
		var node = load(asset).instantiate()
#		print("node: ", node)
		if node.get_node_or_null("./Preview"):
#			print("Preview exist")
			node.get_node("./Preview").preview = false

		var preview_path = database.get_preview(asset_name)
#		print("preview: ", preview_path)
		if ResourceLoader.exists(preview_path):
			var preview_control = TextureRect.new()
			preview_control.texture = load(preview_path)
			preview_control.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			preview_control.size = Vector2(64,64)
			set_drag_preview(preview_control)
		return node
	else:
		return null

func _on_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_at_position = at_position
		asset_popup_menu.popup(Rect2i(get_global_mouse_position(), Vector2i(50,50)))

func _on_item_menu_select(id: int):
#	print("id: ", id)
	match id:
		AssetId.EDIT:
			var idx = get_item_at_position(_at_position, true)
			if idx == -1 or %GameScene.running:
				return null
			var asset_name = get_item_text(idx)
#			print("asset name: ", asset_name)
			var asset_path = database.get_scene(asset_name)
#			print("asset path: ", asset_path)
			if asset_path.get_extension() != "tscn": return
			var asset_editor = asset_editor_packed_scene.instantiate()
			asset_editor.name = &"AssetEditor"
			asset_editor.asset_path = asset_path
			%AssetEditorDialog.add_child(asset_editor)
			%AssetEditorDialog.popup_centered(Vector2i(600, 500))
			
		AssetId.NEW:
			var asset_editor = asset_editor_packed_scene.instantiate()
			asset_editor.name = &"AssetEditor"
			%AssetEditorDialog.add_child(asset_editor)
			%AssetEditorDialog.popup_centered(Vector2i(600, 500))
			
func _on_item_activated(index):
	var asset_name = get_item_text(index)
#	print("item text: ", get_item_text(index))
	var asset_path = database.get_scene(asset_name)
#	print("asset path: ", asset_path)
	if asset_path.get_extension() != "tscn": return
	var asset_editor = asset_editor_packed_scene.instantiate()
	asset_editor.name = &"AssetEditor"
	asset_editor.asset_path = asset_path
	%AssetEditorDialog.add_child(asset_editor)
	%AssetEditorDialog.popup_centered(Vector2i(600, 500))

func _on_new_asset_button_pressed() -> void:
	var asset_editor = asset_editor_packed_scene.instantiate()
	asset_editor.name = &"AssetEditor"
	%AssetEditorDialog.add_child(asset_editor)
	%AssetEditorDialog.popup_centered(Vector2i(600, 500))

func _on_asset_editor_dialog_confirmed():
	var asset_editor = %AssetEditorDialog.get_node_or_null("AssetEditor")
	if asset_editor:
#		print("remove asset editor")
		%AssetEditorDialog.remove_child(asset_editor)
		asset_editor.queue_free()
		update_assets_database()

func _on_asset_editor_dialog_canceled():
	var asset_editor = %AssetEditorDialog.get_node_or_null("AssetEditor")
	if asset_editor:
#		print("remove asset editor")
		%AssetEditorDialog.remove_child(asset_editor)
		asset_editor.queue_free()
		update_assets_database()

func update_assets_database():
	game.load_assets_in_database()
	game.fill_assets_list()
	show_visual_mesh(true)
	show_collision_shape(false)

func show_visual_mesh(enable: bool):
	for node in get_tree().get_nodes_in_group("VISUAL"):
		node.visible = enable
		
func show_collision_shape(enable: bool):
	for node in get_tree().get_nodes_in_group("COLLISION"):
		node.visible = enable
