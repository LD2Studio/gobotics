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

const GOBOTICS_4_MECANUM_DRIVE_TAG = """
	<gobotics name="control_robot" type="4_mecanum_drive">
		<front_right_wheel joint=""/>
		<front_left_wheel joint=""/>
		<back_right_wheel joint=""/>
		<back_left_wheel joint=""/>
		<max_speed value="8.0"/>
	</gobotics>
"""

const GOBOTICS_BUILTIN_RIGHT_MECANUM_WHEEL_TAG = """
	<link name="" builtin="right_mecanum_wheel" />
	</link>
"""

const GOBOTICS_BUILTIN_LEFT_MECANUM_WHEEL_TAG = """
	<link name="" builtin="left_mecanum_wheel" />
	</link>
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
	GOBOTICS_4_MECANUM_DRIVE,
	GOBOTICS_BUILTIN_RIGHT_MECANUM_WHEEL,
	GOBOTICS_BUILTIN_LEFT_MECANUM_WHEEL,
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
	
	menu.add_separator("Gobotics")
	var submenu_gobotics_control = PopupMenu.new()
	submenu_gobotics_control.name = "SubmenuControl"
	submenu_gobotics_control.add_item("Insert Robot Control", Tag.GOBOTICS_CONTROL)
	submenu_gobotics_control.add_item("Insert 4 Mecanum Drive", Tag.GOBOTICS_4_MECANUM_DRIVE)
	submenu_gobotics_control.id_pressed.connect(_on_item_pressed)
	menu.add_child(submenu_gobotics_control)
	menu.add_submenu_item("Control", "SubmenuControl")
	
	var submenu_gobotics_builtin = PopupMenu.new()
	submenu_gobotics_builtin.name = "GoboticsBuiltin"
	submenu_gobotics_builtin.add_item("Insert Right Mecanum Wheel", Tag.GOBOTICS_BUILTIN_RIGHT_MECANUM_WHEEL)
	submenu_gobotics_builtin.add_item("Insert Left Mecanum Wheel", Tag.GOBOTICS_BUILTIN_LEFT_MECANUM_WHEEL)
	submenu_gobotics_builtin.id_pressed.connect(_on_item_pressed)
	menu.add_child(submenu_gobotics_builtin)
	menu.add_submenu_item("Builtin", "GoboticsBuiltin")

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
		Tag.GOBOTICS_4_MECANUM_DRIVE:
			insert_text_at_caret(GOBOTICS_4_MECANUM_DRIVE_TAG)
		Tag.GOBOTICS_BUILTIN_RIGHT_MECANUM_WHEEL:
			insert_text_at_caret(GOBOTICS_BUILTIN_RIGHT_MECANUM_WHEEL_TAG)
		Tag.GOBOTICS_BUILTIN_LEFT_MECANUM_WHEEL:
			insert_text_at_caret(GOBOTICS_BUILTIN_LEFT_MECANUM_WHEEL_TAG)
