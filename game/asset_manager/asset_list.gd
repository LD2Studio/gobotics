extends ItemList

@onready var game: Control = owner
@onready var game_scene = %GameScene
@onready var database: GoboticsDB = owner.database
@onready var asset_popup_menu: PopupMenu = %AssetPopupMenu
@onready var asset_editor_dialog = %AssetEditorDialog

var asset_editor_packed_scene = preload("res://game/asset_editor/asset_editor.tscn")

enum AssetId {
	NEW,
	EDIT,
}

var _at_position: Vector2i
var _asset_updated: StringName = ""

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
			edit_asset(asset_name)
			
			
		AssetId.NEW:
			var asset_editor = asset_editor_packed_scene.instantiate()
			asset_editor.name = &"AssetEditor"
			%AssetEditorDialog.add_child(asset_editor)
			%AssetEditorDialog.popup_centered(Vector2i(600, 500))
			
func _on_item_activated(index):
	var asset_name = get_item_text(index)
#	print("item text: ", get_item_text(index))
	edit_asset(asset_name)
	
func edit_asset(asset_name: String):
	var asset_filename = database.get_scene(asset_name)
#	print_debug("asset filename: ", asset_filename)
	if asset_filename.get_extension() != "tscn": return
	var asset_editor = asset_editor_packed_scene.instantiate()
	asset_editor.name = &"AssetEditor"
	asset_editor.asset_updated.connect(func(value): _asset_updated = value)
	asset_editor.asset_filename = asset_filename
#	asset_editor.asset_path = asset_filename
	%AssetEditorDialog.add_child(asset_editor)
	%AssetEditorDialog.popup_centered(Vector2i(700, 500))

func _on_new_asset_button_pressed() -> void:
	var asset_editor = asset_editor_packed_scene.instantiate()
	asset_editor.name = &"AssetEditor"
	%AssetEditorDialog.add_child(asset_editor)
	%AssetEditorDialog.popup_centered(Vector2i(700, 500))

func _on_asset_editor_dialog_confirmed():
	var asset_editor = %AssetEditorDialog.get_node_or_null("AssetEditor")
	if asset_editor:
#		print("remove asset editor")
		%AssetEditorDialog.remove_child(asset_editor)
		asset_editor.queue_free()
		update_assets_database()
		if game_scene.scene != null:
			update_assets_in_scene()

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
	show_link_frame(false)
	show_joint_frame(false)
	
func update_assets_in_scene():
	var assets = game_scene.scene.get_children()
#	print("assets: ", assets)
#	print("asset updated: ", _asset_updated)
	if _asset_updated == "": return
	for asset in assets:
		if asset.name.begins_with(_asset_updated):
#			print("update asset: ", asset.name)
			var asset_position = asset.get_child(0).global_position
			var asset_rotation = asset.get_child(0).global_rotation
#			print("asset position: ", asset.get_child(0).global_position)
			var asset_name = asset.name
			
			var asset_res = database.get_scene(_asset_updated)
#			print(asset_res)
			var new_asset = load(asset_res).instantiate()
			new_asset.name = asset_name
			
			game_scene.scene.remove_child(asset)
			asset.queue_free()
			
			game_scene.scene.add_child(new_asset)
			new_asset.get_child(0).global_position = asset_position
			new_asset.get_child(0).global_rotation = asset_rotation
			game_scene.connect_editable()
			game_scene.connect_pickable()
			game_scene.freeze_item(new_asset, true)
			
	_asset_updated = ""

func show_visual_mesh(enable: bool):
	for node in get_tree().get_nodes_in_group("VISUAL"):
		node.visible = enable
		
func show_collision_shape(enable: bool):
	for node in get_tree().get_nodes_in_group("COLLISION"):
		node.visible = enable

func show_link_frame(enable: bool):
	for node in get_tree().get_nodes_in_group("LINKS"):
		node.visible = enable

func show_joint_frame(enable: bool):
	for node in get_tree().get_nodes_in_group("JOINTS"):
		node.visible = enable
