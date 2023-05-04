extends ItemList

@onready var database: GoboticsDB = owner.database

func _ready():
	clear()
	for asset in database.assets:
		if asset.group == "ROBOTS" or asset.group == "PROPS":
			add_item(asset.name)

func _get_drag_data(at_position: Vector2):
	var idx = get_item_at_position(at_position, true)
	if idx == -1 or %GameScene.running:
		return null

	var asset_name = get_item_text(idx)
	var asset = database.get_scene(asset_name)
#	print(asset)
	if asset:
		var node = load(asset).instantiate()
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
