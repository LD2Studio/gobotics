extends ItemList

@onready var database: GoboticsDB = owner.database

func _ready() -> void:
	clear()
	for environment in database.environments:
		add_item(environment.name)

