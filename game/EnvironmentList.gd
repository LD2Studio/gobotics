extends ItemList

@onready var database: GoboticsDB = owner.database

func _ready() -> void:
	clear()
	for asset in database.assets:
		if asset.group == "ENVIRONMENT":
			add_item(asset.name)

