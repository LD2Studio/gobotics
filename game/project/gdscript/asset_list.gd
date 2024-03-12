extends ItemList

# The updated asset is located int the %AssetEditorDialog.get_meta("fullname") 

@onready var game: Control = owner
@onready var game_scene: Node3D = %GameScene
@onready var asset_popup_menu: PopupMenu = %AssetPopupMenu
@onready var asset_editor_dialog = %AssetEditorDialog
@onready var new_asset_button = %NewAssetButton
@onready var asset_duplicate_dialog: ConfirmationDialog = %AssetDuplicateDialog

enum AssetPopup {
	EDIT,
	DUPLICATE,
	DELETE,
}

var asset_updated: String = "":
	set(value):
		asset_updated = value
#		print("asset updated: ", asset_updated)
		GSettings.database.update_asset(asset_updated)
		update_assets_list()
		
var _asset_editor_rect: Rect2i


func _ready() -> void:
	asset_popup_menu.add_item("Edit", AssetPopup.EDIT)
	asset_popup_menu.add_item("Duplicate", AssetPopup.DUPLICATE)
	asset_popup_menu.add_item("Delete", AssetPopup.DELETE)
	asset_popup_menu.id_pressed.connect(_on_item_menu_select)


func _get_drag_data(at_position: Vector2):
	var idx = get_item_at_position(at_position, true)
	if idx == -1: return null
	# INFO: get asset fullname like "demo/ball.urdf"
	var fullname = get_item_metadata(idx)
	var type = GSettings.database.get_type(fullname)
	if type and type == "standalone" or type == "robot":
		var node: Node3D = load(GSettings.database.get_scene_from_fullname(fullname)).instantiate()
		
		#var preview_path = database.get_preview(asset_name)
		#print("preview: ", preview_path)
		#if ResourceLoader.exists(preview_path):
			#var preview_control = TextureRect.new()
			#preview_control.texture = load(preview_path)
			#preview_control.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			#preview_control.size = Vector2(64,64)
			#set_drag_preview(preview_control)
		return node
	else:
		return null


func _on_item_clicked(index: int, _at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		deselect_all()
		select(index)
		asset_popup_menu.popup(Rect2i(get_global_mouse_position(), Vector2i(50,50)))


func _on_item_menu_select(id: int):
	var selected_fullname: String = get_item_metadata(get_selected_items()[0])
	match id:
		AssetPopup.EDIT:
			edit_asset(selected_fullname)
		AssetPopup.DUPLICATE:
			duplicate_asset(selected_fullname)
		AssetPopup.DELETE:
			delete_asset(selected_fullname)


func _on_item_activated(index):
	var fullname = get_item_metadata(index)
	edit_asset(fullname)


func edit_asset(fullname: String):
	var asset_editor: AssetEditor = preload("res://game/asset_editor/asset_editor.tscn").instantiate()
	asset_editor.name = &"AssetEditor"
	asset_editor.fullscreen_toggled.connect(_on_fullscreen_toggled)
	asset_editor.asset_fullname = fullname
	asset_editor_dialog.add_child(asset_editor)
	asset_editor_dialog.popup_centered_ratio(0.8)


func create_new_asset(asset_type: GSettings.AssetType):
	var asset_editor: AssetEditor = preload("res://game/asset_editor/asset_editor.tscn").instantiate()
	asset_editor.name = &"AssetEditor"
	asset_editor.fullscreen_toggled.connect(_on_fullscreen_toggled)
	asset_editor.asset_type = asset_type
	asset_editor_dialog.add_child(asset_editor)
	asset_editor_dialog.popup_centered_ratio(0.8)


func _on_asset_editor_exited():
	var asset_editor = %AssetEditorDialog.get_node_or_null("AssetEditor")
	if asset_editor:
		asset_editor_dialog.remove_child(asset_editor)
		asset_editor.queue_free()
		%AssetEditorDialog.visible = false
		update_scene()


func duplicate_asset(fullname: String):
	asset_duplicate_dialog.get_node("VBoxContainer/Message").text = (
		"Duplicate the \"%s\" project under the name :" % [fullname])
	asset_duplicate_dialog.get_node("VBoxContainer/AssetFullnameEdit").text = fullname
	asset_duplicate_dialog.get_ok_button().disabled = true
	asset_duplicate_dialog.set_meta("asset_fullname", fullname)
	asset_duplicate_dialog.popup_centered()


func _on_asset_fullname_edit_text_changed(new_asset_fullname: String) -> void:
	if GSettings.database.is_asset_exists(new_asset_fullname):
		asset_duplicate_dialog.get_ok_button().disabled = true
	else:
		asset_duplicate_dialog.get_ok_button().disabled = false


func _on_asset_duplicate_dialog_confirmed() -> void:
	var asset_fullname = asset_duplicate_dialog.get_meta("asset_fullname")
	if asset_fullname == null: return
	var new_asset_fullname = asset_duplicate_dialog.get_node(
		"VBoxContainer/AssetFullnameEdit").text
	DirAccess.copy_absolute(
		GSettings.asset_path.path_join(asset_fullname),
		GSettings.asset_path.path_join(new_asset_fullname)
	)
	update_assets_database()


func delete_asset(fullname: String):
	%DeleteConfirmationDialog.dialog_text = "Do you want to delete the asset file \"%s\"" % [fullname]
	%DeleteConfirmationDialog.set_meta("asset_fullname", fullname)
	%DeleteConfirmationDialog.popup_centered()


func _on_delete_confirmation_dialog_confirmed():
	var fullname = %DeleteConfirmationDialog.get_meta("asset_fullname", "")
	var filename = GSettings.database.get_asset_filename(fullname)
	if filename:
		OS.move_to_trash(filename)
		GSettings.database.generate()
		update_assets_database()
		game_scene.save_project()


func update_assets_database():
	game.load_assets_in_database()
	update_assets_list()
	show_visual_mesh(true)
	show_collision_shape(false)
	show_link_frame(false)
	show_joint_frame(false)


func update_assets_list():
	clear()
	for asset in GSettings.database.assets:
		if asset.type == "builtin_env": continue
		var idx = add_item(asset.name)
		set_item_metadata(idx, asset.fullname)
		set_item_tooltip(idx, asset.fullname)


func update_scene():
	var scene_node = game_scene.get_node_or_null("Scene")
	if not scene_node: return
	var assets = get_tree().get_nodes_in_group("ASSETS")
#	print("[AL] assets: ", assets)
	for asset in assets:
		var fullname = asset.get_meta("fullname")
		if fullname == null: continue
		
		game_scene._selected_asset = null
		if fullname != asset_updated: continue
		
		if GSettings.database.is_asset_exists(fullname):
			var asset_tr: Transform3D
			for node in asset.get_children():
				if node is RigidBody3D:
					asset_tr = node.global_transform
					break
			if not asset_tr: continue
			var asset_name : StringName = asset.name
#			print("update asset %s" % [asset.get_meta("fullname")])
			var udp_port: int = asset.get_meta("udp_port", -1)
			scene_node.remove_child(asset)
			asset.queue_free()
			var new_asset_scene : String = GSettings.database.get_scene_from_fullname(fullname)
			var new_asset : Node3D = load(new_asset_scene).instantiate()
			new_asset.name = asset_name
			new_asset.global_transform = asset_tr
			new_asset.set_meta("udp_port", udp_port)
			game_scene.set_physics(new_asset, true)
			scene_node.add_child(new_asset)
			
	game_scene.update_robot_select_menu()
	game_scene.update_camera_view_menu()
	
	
func update_assets_in_scene():
	var updated_asset = %AssetEditorDialog.get_meta("fullname", "")
	if updated_asset == null or updated_asset == "": return
	#print("updated asset: ", updated_asset)
	var assets = game_scene.scene.get_children()
	#print("assets: ", assets)
	for asset in assets:
		if asset.get_meta("fullname", "") == updated_asset:
			var base_link: RigidBody3D = asset.get_children().filter(
					func(child): return child is RigidBody3D).front()
			if base_link == null: continue
			var asset_position = base_link.global_position
			var asset_rotation = base_link.global_rotation
			var asset_name = asset.name
			game_scene.scene.remove_child(asset)
			asset.queue_free()
			
			var asset_res = GSettings.database.get_asset_scene(updated_asset)
			var new_asset = load(asset_res).instantiate()
			new_asset.name = asset_name
			
			game_scene.scene.add_child(new_asset)
			base_link = new_asset.get_children().filter(
					func(child): return child is RigidBody3D).front()
			if base_link == null: continue
			base_link.global_position = asset_position
			base_link.global_rotation = asset_rotation
			game_scene.set_physics(new_asset, true)
			
	game_scene.update_robot_select_menu()
	game_scene.update_camera_view_menu()
	%AssetEditorDialog.set_meta("fullname", "")


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
