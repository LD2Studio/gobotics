extends ItemList

func update_list():
	clear()
	for asset in GSettings.database.assets:
		if asset.type == "env" or asset.type == "builtin_env":
			var idx = add_item(asset.name)
			set_item_metadata(idx, asset.scene)
