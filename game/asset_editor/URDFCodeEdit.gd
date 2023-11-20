extends CodeEdit

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
	SENSOR_RAY,
	GOBOTICS_CONTROL,
	GOBOTICS_4_MECANUM_DRIVE,
	GOBOTICS_GROUPED_JOINTS,
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
	
	var submenu_sensors = PopupMenu.new()
	submenu_sensors.name = "SubmenuSensors"
	submenu_sensors.add_item("Insert Ray Sensor", Tag.SENSOR_RAY)
	submenu_sensors.id_pressed.connect(_on_item_pressed)
	menu.add_child(submenu_sensors)
	menu.add_submenu_item("Sensors", "SubmenuSensors")
	
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
	submenu_gobotics_control.add_item("Insert Grouped Joints", Tag.GOBOTICS_GROUPED_JOINTS)
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
			insert_text_at_caret(URDFTemplate.LINK_FULL_TAG)
			set_caret_line(get_caret_line() - 2)
		Tag.VISUAL:
			insert_text_at_caret(URDFTemplate.VISUAL_FULL_TAG)
			set_caret_line(get_caret_line() - 6)
		Tag.COLLISION:
			insert_text_at_caret(URDFTemplate.COLLISION_FULL_TAG)
			set_caret_line(get_caret_line() - 3)
		Tag.INERTIAL:
			insert_text_at_caret(URDFTemplate.INERTIAL_MINIMAL_TAG)
		Tag.MATERIAL:
			insert_text_at_caret(URDFTemplate.MATERIAL_MINIMAL_TAG)
		Tag.JOINT_PRISMATIC:
			insert_text_at_caret(URDFTemplate.JOINT_PRISMATIC_TAG)
		Tag.JOINT_CONTINUOUS:
			insert_text_at_caret(URDFTemplate.JOINT_CONTINUOUS_TAG)
		Tag.JOINT_REVOLUTE:
			insert_text_at_caret(URDFTemplate.JOINT_REVOLUTE_TAG)
		Tag.JOINT_PIN:
			insert_text_at_caret(URDFTemplate.JOINT_PIN_TAG)
		Tag.SENSOR_RAY:
			insert_text_at_caret(URDFTemplate.SENSOR_RAY_TAG)
		Tag.BOX:
			insert_text_at_caret(URDFTemplate.BOX_GEOMETRY_TAG)
		Tag.SPHERE:
			insert_text_at_caret(URDFTemplate.SPHERE_GEOMETRY_TAG)
		Tag.CYLINDER:
			insert_text_at_caret(URDFTemplate.CYLINDER_GEOMETRY_TAG)
		Tag.MESH:
			insert_text_at_caret(URDFTemplate.MESH_GEOMETRY_TAG)
		Tag.INLINE_COLOR:
			insert_text_at_caret(URDFTemplate.INLINE_COLOR_TAG)
		Tag.GOBOTICS_CONTROL:
			insert_text_at_caret(URDFTemplate.GOBOTICS_CONTROL_TAG)
		Tag.GOBOTICS_4_MECANUM_DRIVE:
			insert_text_at_caret(URDFTemplate.GOBOTICS_4_MECANUM_DRIVE_TAG)
		Tag.GOBOTICS_GROUPED_JOINTS:
			insert_text_at_caret(URDFTemplate.GOBOTICS_GROUPED_JOINTS_TAG)
		Tag.GOBOTICS_BUILTIN_RIGHT_MECANUM_WHEEL:
			insert_text_at_caret(URDFTemplate.GOBOTICS_BUILTIN_RIGHT_MECANUM_WHEEL_TAG)
		Tag.GOBOTICS_BUILTIN_LEFT_MECANUM_WHEEL:
			insert_text_at_caret(URDFTemplate.GOBOTICS_BUILTIN_LEFT_MECANUM_WHEEL_TAG)
