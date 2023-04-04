extends ItemList

func _ready():
	clear()
	for block in BlocksDB.list:
		add_item(block.name)

func _get_drag_data(at_position: Vector2):
	var item_idx = get_item_at_position(at_position, true)
	if item_idx == -1 or %GameScene.running:
		return null
	var item_text = get_item_text(item_idx)
#	print_debug("item text : %s" % [item_text])
#	print("block path: %s" % BlocksDB.get_block_path(item_text))
	var block_path = BlocksDB.get_block_path(item_text)
	if block_path:
		var node = load(block_path).instantiate()
		node.add_to_group("BLOCKS")
		var preview_path = BlocksDB.get_preview(item_text)
		if preview_path:
			var preview = TextureRect.new()
			preview.texture = load(preview_path)
			set_drag_preview(preview)
		return node
	else:
		return null
