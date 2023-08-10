extends ItemList

@onready var database: GoboticsDB = owner.database

func _ready() -> void:
	clear()
#	for environment in database.environments:
	for asset in database.assets:
		if asset.type == "env":
			var idx = add_item(asset.name)
			set_item_metadata(idx, asset.fullname)

