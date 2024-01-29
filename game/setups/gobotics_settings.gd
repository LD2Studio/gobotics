class_name GoboticsSettings extends Node
## Singleton GoboticsSettings
##
## Stocke la configuration du jeu Gobotics

## Chemin vers les projets utilisateur de Gobotics.
var project_path: String:
	get:
		return (ProjectSettings.globalize_path(projects_editor_path)
			if OS.has_feature("editor")
			else ProjectSettings.globalize_path(projects_export_path))

var projects_editor_path: String = "res://projects"
var projects_export_path: String = "user://projects"

var asset_dir : String = "assets"
var asset_base_dir: String
var temp_path: String = "temp"

var database: GoboticsDB = GoboticsDB.new(temp_path)

