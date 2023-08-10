extends Button

@onready var new_asset_menu = %NewAssetMenu
@onready var game_scene = %GameScene
@onready var asset_list = %AssetList

enum NewAsset {
	STANDALONE,
	ROBOT,
	ENVIRONMENT,
}

func _ready():
	new_asset_menu.add_item("Standalone", NewAsset.STANDALONE)
	new_asset_menu.add_item("Robot", NewAsset.ROBOT)
	new_asset_menu.add_item("Environment", NewAsset.ENVIRONMENT)
	new_asset_menu.id_pressed.connect(_on_item_menu_select)

func _on_pressed():
	if game_scene.running: return
	new_asset_menu.popup(Rect2i(global_position + Vector2(30, 0), Vector2i(50,50)))
	
func _on_item_menu_select(id: int):
	
	asset_list.create_new_asset(id)
