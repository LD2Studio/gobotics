class_name RobotsDB
extends Resource

@export var assets_path: String = "res://assets"
@export var robots: Array
var robots_dir: String = "res://robots"

func create():
	if OS.has_feature("editor"):
		pass
	else:
		var executable_path: String = OS.get_executable_path()
		print_debug(executable_path)
	var files = Array(DirAccess.get_files_at(robots_dir))
	# Filter tscn files
	var files_tscn: Array = files.filter(func(file): return file.get_extension() == "tscn")

	for file in files_tscn:
		var robot_scn = load(robots_dir.path_join(file))
		if "ROBOTS" in robot_scn.get_state().get_node_groups(0):
			var name = robot_scn.get_state().get_node_name(0)
			var preview_filename: String
			for idx in robot_scn.get_state().get_node_count():
#				print("%d: %s" % [idx, robot_scn.get_state().get_node_name(idx)])
				if robot_scn.get_state().get_node_name(idx) == "Preview":
#					print("Property count: %d" % robot_scn.get_state().get_node_property_count(idx))
					for j in robot_scn.get_state().get_node_property_count(idx):
#						print("property %s = %s" % [robot_scn.get_state().get_node_property_name(idx, j),
#							robot_scn.get_state().get_node_property_value(idx, j)])
						if robot_scn.get_state().get_node_property_name(idx, j) == "filename":
							preview_filename = robots_dir.path_join(robot_scn.get_state().get_node_property_value(idx, j)+".png")
			if preview_filename == "":
				preview_filename = robots_dir.path_join(name+".png")
			var path = robots_dir.path_join(file)
			robots.append({
				name=name,
				path=path,
				preview=preview_filename,
			})
		
	ResourceSaver.save(self, robots_dir.path_join("robots_db.tres"))

func get_dir(name: String):
	for robot in robots:
		if robot.name == name:
			return robot.path
	return null
	
func get_preview(name: String):
	for robot in robots:
		if robot.name == name:
			return robot.preview
	return null
