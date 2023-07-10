extends CodeEdit

const LINK_FULL_TAG = """
	<link name="link_name">
	
	</link>
"""
const VISUAL_FULL_TAG = """
		<visual name="">
			<origin xyz="0 0 0" rpy="0 0 0"/>
			<geometry>
			
			</geometry>
			<material>
			
			</material>
		</visual>
"""
const COLLISION_FULL_TAG = """
		<collision name="">
			<origin xyz="0 0 0" rpy="0 0 0"/>
			<geometry>
			
			</geometry>
		</collision>
"""
const BOX_GEOMETRY_TAG = """<box size="0.1 0.1 0.1"/>"""
const SPHERE_GEOMETRY_TAG = """<sphere radius="0.1"/>"""

const INLINE_COLOR_TAG = """<color rgba="0 0 0 1"/>"""
enum Tag {
	LINK = MENU_MAX + 1,
	MATERIAL,
	VISUAL,
	COLLISION,
	BOX,
	SPHERE,
	CYLINDER,
	MESH,
	INLINE_COLOR,
}

# Called when the node enters the scene tree for the first time.
func _ready():
	var menu = get_menu()
	# Remove all items after "Redo".
	menu.item_count = menu.get_item_index(MENU_REDO) + 1
	# Add custom items.
	menu.add_separator()
	menu.add_item("Insert Link", Tag.LINK)
	menu.add_item("Insert Visual", Tag.VISUAL)
	menu.add_item("Insert Collision", Tag.COLLISION)
	menu.add_separator()
	menu.add_item("Insert Box geometry", Tag.BOX)
	menu.add_item("Insert Sphere geometry", Tag.SPHERE)
	menu.add_item("Insert Inline Color", Tag.INLINE_COLOR)
	# Connect callback.
	menu.id_pressed.connect(_on_item_pressed)

func _on_item_pressed(id):
	match id:
		Tag.LINK:
			insert_text_at_caret(LINK_FULL_TAG)
			set_caret_line(get_caret_line() - 2)
		Tag.VISUAL:
			insert_text_at_caret(VISUAL_FULL_TAG)
			set_caret_line(get_caret_line() - 6)
		Tag.COLLISION:
			insert_text_at_caret(COLLISION_FULL_TAG)
			set_caret_line(get_caret_line() - 3)
		Tag.BOX:
			insert_text_at_caret(BOX_GEOMETRY_TAG)
		Tag.SPHERE:
			insert_text_at_caret(SPHERE_GEOMETRY_TAG)
		Tag.INLINE_COLOR:
			insert_text_at_caret(INLINE_COLOR_TAG)
	
