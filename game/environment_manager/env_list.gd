extends ItemList

@onready var database: GoboticsDB = owner.database

func _ready() -> void:
	update_list()

func update_list():
	clear()
	for asset in database.assets:
		if asset.type == "env" or asset.type == "builtin_env":
			var idx = add_item(asset.name)
			set_item_metadata(idx, asset.scene)
