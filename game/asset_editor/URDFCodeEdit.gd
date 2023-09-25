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
			<material name="">
			
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
const INERTIAL_FULL_TAG = """
		<inertial>
			<origin xyz="0 0 0" rpy="0 0 0"/>
			<mass value="0.1"/>
		</inertial>
"""
const INERTIAL_MINIMAL_TAG = """
		<inertial>
			<mass value="0.1"/>
		</inertial>
"""
const MATERIAL_MINIMAL_TAG = """
	<material name="white">
		<color rgba="1 1 1 1"/>
	</material>
"""
const JOINT_CONTINUOUS_TAG = """
	<joint name="joint_name" type="continuous">
		<origin xyz="0 0 0" rpy="0 0 0"/>
		<parent link=""/>
		<child link=""/>
		<axis xyz="1.0 0.0 0.0"/>
		<limit effort="1.0" velocity="5.0"/>
	</joint>
"""
const JOINT_REVOLUTE_TAG = """
	<joint name="joint_name" type="revolute">
		<origin xyz="0 0 0" rpy="0 0 0"/>
		<parent link=""/>
		<child link=""/>
		<axis xyz="1.0 0.0 0.0"/>
		<limit lower="0.0" upper="0.0" effort="1.0" velocity="5.0"/>
	</joint>
"""
const JOINT_PRISMATIC_TAG = """
	<joint name="joint_name" type="prismatic">
		<origin xyz="0 0 0" rpy="0 0 0"/>
		<parent link=""/>
		<child link=""/>
		<axis xyz="1.0 0.0 0.0"/>
		<limit lower="0.0" upper="0.0" effort="1.0" velocity="5.0"/>
	</joint>
"""
const JOINT_PIN_TAG = """
	<joint name="joint_name" type="pin">
		<origin xyz="0 0 0" rpy="0 0 0"/>
		<parent link=""/>
		<child link=""/>
	</joint>
"""
const BOX_GEOMETRY_TAG = """<box size="0.1 0.1 0.1"/>"""
const SPHERE_GEOMETRY_TAG = """<sphere radius="0.1"/>"""
const CYLINDER_GEOMETRY_TAG = """<cylinder radius="0.1" length="0.2"/>"""
const MESH_GEOMETRY_TAG = """<mesh filename="package://" object="" />"""

const INLINE_COLOR_TAG = """<color rgba="0 0 0 1"/>"""

const GOBOTICS_CONTROL_TAG = """
	<gobotics name="control_robot" type="diff_drive">
		<right_wheel joint=""/>
		<left_wheel joint=""/>
		<max_speed value="6.0"/>
	</gobotics>
"""

enum Tag {
	LINK = MENU_MAX + 1,
	MATERIAL,
	VISUAL,
	COLLISION,
	INERTIAL,
	BOX,
	SPHERE,
	CYLINDER,
	MESH,
	INLINE_COLOR,
	JOINT_CONTINUOUS,
	JOINT_REVOLUTE,
	JOINT_PRISMATIC,
	JOINT_PIN,
	GOBOTICS_CONTROL,
}

func _ready():
	var menu = get_menu()
	# Remove all items after "Redo".
	menu.item_count = menu.get_item_index(MENU_REDO) + 1
	# Add custom items.
	menu.add_separator()
	menu.add_item("Insert Link", Tag.LINK)
	menu.add_item("Insert Visual", Tag.VISUAL)
	menu.add_item("Insert Collision", Tag.COLLISION)
	menu.add_item("Insert Inertial", Tag.INERTIAL)
	menu.add_item("Insert Material", Tag.MATERIAL)
	menu.id_pressed.connect(_on_item_pressed)
	
	menu.add_separator()
	var submenu_joint = PopupMenu.new()
	submenu_joint.name = "SubmenuJoint"
	submenu_joint.add_item("Insert Continuous Joint", Tag.JOINT_CONTINUOUS)
	submenu_joint.add_item("Insert Revolute Joint", Tag.JOINT_REVOLUTE)
	submenu_joint.add_item("Insert Prismatic Joint", Tag.JOINT_PRISMATIC)
	submenu_joint.add_item("Insert Pin Joint", Tag.JOINT_PIN)
	submenu_joint.id_pressed.connect(_on_item_pressed)
	menu.add_child(submenu_joint)
	menu.add_submenu_item("Joints", "SubmenuJoint")
	
	menu.add_separator()
	var submenu_geometry = PopupMenu.new()
	submenu_geometry.name = "SubmenuGeometry"
	submenu_geometry.add_item("Insert Box", Tag.BOX)
	submenu_geometry.add_item("Insert Sphere", Tag.SPHERE)
	submenu_geometry.add_item("Insert Cylinder", Tag.CYLINDER)
	submenu_geometry.add_item("Insert Mesh", Tag.MESH)
	submenu_geometry.id_pressed.connect(_on_item_pressed)
	menu.add_child(submenu_geometry)
	menu.add_submenu_item("Geometry", "SubmenuGeometry")
	menu.add_item("Insert Inline Color", Tag.INLINE_COLOR)
	
	menu.add_separator()
	var submenu_gobotics = PopupMenu.new()
	submenu_gobotics.name = "SubmenuGobotics"
	submenu_gobotics.add_item("Insert Robot Control", Tag.GOBOTICS_CONTROL)
	submenu_gobotics.id_pressed.connect(_on_item_pressed)
	menu.add_child(submenu_gobotics)
	menu.add_submenu_item("Gobotics", "SubmenuGobotics")

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
		Tag.INERTIAL:
			insert_text_at_caret(INERTIAL_MINIMAL_TAG)
		Tag.MATERIAL:
			insert_text_at_caret(MATERIAL_MINIMAL_TAG)
		Tag.JOINT_PRISMATIC:
			insert_text_at_caret(JOINT_PRISMATIC_TAG)
		Tag.JOINT_CONTINUOUS:
			insert_text_at_caret(JOINT_CONTINUOUS_TAG)
		Tag.JOINT_REVOLUTE:
			insert_text_at_caret(JOINT_REVOLUTE_TAG)
		Tag.JOINT_PIN:
			insert_text_at_caret(JOINT_PIN_TAG)
		Tag.BOX:
			insert_text_at_caret(BOX_GEOMETRY_TAG)
		Tag.SPHERE:
			insert_text_at_caret(SPHERE_GEOMETRY_TAG)
		Tag.CYLINDER:
			insert_text_at_caret(CYLINDER_GEOMETRY_TAG)
		Tag.MESH:
			insert_text_at_caret(MESH_GEOMETRY_TAG)
		Tag.INLINE_COLOR:
			insert_text_at_caret(INLINE_COLOR_TAG)
		Tag.GOBOTICS_CONTROL:
			insert_text_at_caret(GOBOTICS_CONTROL_TAG)
