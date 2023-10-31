extends ItemList

@onready var game: Control = owner
@onready var game_scene = %GameScene
@onready var database: GoboticsDB = owner.database
@onready var asset_popup_menu: PopupMenu = %AssetPopupMenu
@onready var asset_editor_dialog = %AssetEditorDialog
@onready var new_asset_button = %NewAssetButton

var asset_editor_packed_scene = preload("res://game/asset_editor/asset_editor.tscn")

enum AssetId {
	EDIT,
	DELETE,
}

var asset_updated: String = "":
	set(value):
		asset_updated = value
#		print("asset updated: ", asset_updated)
		database.update_asset(asset_updated)
		
var _at_position: Vector2i
var _asset_editor_rect: Rect2i
var selected_asset_filename: String

func _ready() -> void:
	asset_popup_menu.add_item("Edit", AssetId.EDIT)
	asset_popup_menu.add_item("Delete", AssetId.DELETE)
	asset_popup_menu.id_pressed.connect(_on_item_menu_select)

func _get_drag_data(at_position: Vector2):
	var idx = get_item_at_position(at_position, true)
	if idx == -1 or %GameScene.running:
		return null

	var fullname = get_item_metadata(idx)
	var asset = database.get_scene_from_fullname(fullname)
	var type = database.get_type(fullname)
	if asset and type and type == "standalone" or type == "robot":
		var node: Node3D = load(asset).instantiate()
		if node.get_node_or_null("./Preview"):
#			print("Preview exist")
			node.get_node("./Preview").preview = false

#		var preview_path = database.get_preview(asset_name)
#		print("preview: ", preview_path)
#		if ResourceLoader.exists(preview_path):
#			var preview_control = TextureRect.new()
#			preview_control.texture = load(preview_path)
#			preview_control.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
#			preview_control.size = Vector2(64,64)
#			set_drag_preview(preview_control)
		return node
	else:
		return null

func _on_item_clicked(_index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_at_position = at_position
		asset_popup_menu.popup(Rect2i(get_global_mouse_position(), Vector2i(50,50)))

func _on_item_menu_select(id: int):
	match id:
		AssetId.EDIT:
			var idx = get_item_at_position(_at_position, true)
			if idx == -1 or %GameScene.running:
				return null
			var fullname = get_item_metadata(idx)
			edit_asset(fullname)
			
		AssetId.DELETE:
			var idx = get_item_at_position(_at_position, true)
			if idx == -1 or %GameScene.running:
				return null
			var fullname = get_item_metadata(idx)
			delete_asset(fullname)
			
func _on_item_activated(index):
	var fullname = get_item_metadata(index)
	edit_asset(fullname)
	
func edit_asset(fullname: String):
	var asset_editor = asset_editor_packed_scene.instantiate()
	asset_editor.name = &"AssetEditor"
	asset_editor.asset_base_dir = game.asset_base_dir
	asset_editor.asset_updated.connect(func(value): asset_updated = value)
	asset_editor.fullscreen_toggled.connect(_on_fullscreen_toggled)
	asset_editor.asset_fullname = fullname
	asset_editor_dialog.add_child(asset_editor)
	asset_editor_dialog.popup_centered(Vector2i(700, 500))
	
func create_new_asset(asset_type: int):
	var asset_editor = asset_editor_packed_scene.instantiate()
	asset_editor.name = &"AssetEditor"
	asset_editor.asset_base_dir = game.asset_base_dir
	asset_editor.asset_updated.connect(func(value): asset_updated = value)
	asset_editor.fullscreen_toggled.connect(_on_fullscreen_toggled)
	asset_editor.asset_type = asset_type
	asset_editor_dialog.add_child(asset_editor)
	asset_editor_dialog.popup_centered(Vector2i(700, 500))

func _on_asset_editor_dialog_confirmed():
	var asset_editor = %AssetEditorDialog.get_node_or_null("AssetEditor")
	if asset_editor:
		asset_editor_dialog.remove_child(asset_editor)
		asset_editor.queue_free()
		update_scene()

func _on_asset_editor_dialog_canceled():
	var asset_editor = %AssetEditorDialog.get_node_or_null("AssetEditor")
	if asset_editor:
		asset_editor_dialog.remove_child(asset_editor)
		asset_editor.queue_free()
		update_assets_database()
		
func delete_asset(fullname: String):
	selected_asset_filename = database.get_asset_filename(fullname)
	%DeleteConfirmationDialog.dialog_text = "Do you want to delete the asset file \"%s\"" % [fullname]
	%DeleteConfirmationDialog.popup_centered()
	
func _on_delete_confirmation_dialog_confirmed():
#	DirAccess.remove_absolute(selected_asset_filename)
	OS.move_to_trash(selected_asset_filename)
	update_assets_database()
	update_assets_in_scene()

func update_assets_database():
	game.load_assets_in_database()
	game.fill_assets_list()
	show_visual_mesh(true)
	show_collision_shape(false)
	show_link_frame(false)
	show_joint_frame(false)
	
func update_assets_list():
	game.fill_assets_list()
	
func update_scene():
	var scene_node = game_scene.get_node_or_null("Scene")
	if not scene_node: return
	var assets = get_tree().get_nodes_in_group("ASSETS")
#	print("[AL] assets: ", assets)
	for asset in assets:
		var fullname = asset.get_meta("fullname")
		if fullname == null: continue
		game_scene.asset_selected = null
		if fullname != asset_updated: continue
		if database.is_asset_exists(fullname):
			var asset_tr: Transform3D
			for node in asset.get_children():
				if node is RigidBody3D:
					asset_tr = node.global_transform
					break
			if not asset_tr: continue
			
#			print("update asset %s" % [asset.get_meta("fullname")])
			scene_node.remove_child(asset)
			asset.queue_free()
			var new_asset_scene : String = database.get_scene_from_fullname(fullname)
			var new_asset : Node3D = load(new_asset_scene).instantiate()
			new_asset.global_transform = asset_tr
			game_scene.freeze_asset(new_asset, true)
			scene_node.add_child(new_asset)
			
	game_scene.connect_editable()
	game_scene.update_robot_select_menu()
	game_scene.update_camera_view_menu()
	
	
func update_assets_in_scene():
	var assets = get_tree().get_nodes_in_group("ASSETS")
	if asset_updated == "": return
	for asset in assets:
		if asset.get_meta("fullname") == asset_updated:
			var asset_position = asset.get_child(0).global_position
			var asset_rotation = asset.get_child(0).global_rotation
			var asset_name = asset.name
			game_scene.scene.remove_child(asset)
			asset.free()
			
			var asset_res = database.get_asset_scene(asset_updated)
			var new_asset = load(asset_res).instantiate()
			new_asset.name = asset_name
			
			game_scene.scene.add_child(new_asset)
			new_asset.get_child(0).global_position = asset_position
			new_asset.get_child(0).global_rotation = asset_rotation
			game_scene.connect_editable()
			game_scene.connect_pickable()
			game_scene.freeze_asset(new_asset, true)
	game_scene.update_camera_view_menu()
	asset_updated = ""

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

func _on_fullscreen_toggled(button_pressed: bool):
	if button_pressed:
		_asset_editor_rect = Rect2i(asset_editor_dialog.position, asset_editor_dialog.size)
		asset_editor_dialog.position = Vector2i(0,0)
		asset_editor_dialog.size = get_tree().root.size - Vector2i(0,30)
		if not get_tree().root.size_changed.is_connected(_on_asset_editor_dialog_size_changed):
			get_tree().root.size_changed.connect(_on_asset_editor_dialog_size_changed)
	else:
		asset_editor_dialog.position = _asset_editor_rect.position
		asset_editor_dialog.size = _asset_editor_rect.size
		get_tree().root.size_changed.disconnect(_on_asset_editor_dialog_size_changed)

func _on_asset_editor_dialog_size_changed():
	asset_editor_dialog.position = Vector2i(0,0)
	asset_editor_dialog.size = get_tree().root.size - Vector2i(0,30)
