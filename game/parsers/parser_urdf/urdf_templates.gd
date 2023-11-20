extends Object
class_name URDFTemplate

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
		<limit lower="0.0" upper="0.0" effort="10.0" velocity="1.0"/>
	</joint>
"""
const JOINT_PRISMATIC_TAG = """
	<joint name="joint_name" type="prismatic">
		<origin xyz="0 0 0" rpy="0 0 0"/>
		<parent link=""/>
		<child link=""/>
		<axis xyz="1.0 0.0 0.0"/>
		<limit lower="0.0" upper="0.0" effort="10.0" velocity="0.5"/>
	</joint>
"""
const JOINT_PIN_TAG = """
	<joint name="joint_name" type="pin">
		<origin xyz="0 0 0" rpy="0 0 0"/>
		<parent link=""/>
		<child link=""/>
	</joint>
"""
const SENSOR_RAY_TAG = """
	<sensor name="sensor_name" type="ray" update_rate="">
		<origin xyz="0 0 0" rpy="0 0 0"/>
		<parent link=""/>
		<ray>
			<horizontal samples="1" resolution="1.0" min_angle="0" max_angle="0"/>
			<vertical samples="1" resolution="1.0" min_angle="0" max_angle="0"/>
			<range min="0" max="1"/>
		</ray>
	</sensor>
"""
const BOX_GEOMETRY_TAG = """<box size="0.1 0.1 0.1"/>"""
const SPHERE_GEOMETRY_TAG = """<sphere radius="0.1"/>"""
const CYLINDER_GEOMETRY_TAG = """<cylinder radius="0.1" length="0.2"/>"""
const MESH_GEOMETRY_TAG = """<mesh filename="" />"""

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

const GOBOTICS_GROUPED_JOINTS_TAG = """
	<gobotics name="control_joints" type="grouped_joints">
		<input name="" lower="0.0" upper="0.0"/>
		<output joint="" factor="1.0"/>
		<output joint="" factor="1.0"/>
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
