class_name GoboticsSettings extends Node
## Singleton GoboticsSettings
##
## Stocke la configuration du jeu Gobotics

## Chemin vers les projets utilisateur de Gobotics.
var project_path: String:
	get:
		return (ProjectSettings.globalize_path(_project_editor_path)
			if OS.has_feature("editor")
			else ProjectSettings.globalize_path(_project_export_path))

var _project_editor_path = "res://projects"
var _project_export_path = "user://projects"

## Chemin vers les assets de Gobotics.
var asset_path: String:
	get:
		return (ProjectSettings.globalize_path(_asset_editor_path)
			if OS.has_feature("editor")
			else ProjectSettings.globalize_path(_asset_export_path))

var _asset_editor_path: String = "res://assets"
var _asset_export_path: String = "user://assets"

## Chemin vers les fichiers temporaires de Gobotics.
var temp_path: String:
	get:
		return (ProjectSettings.globalize_path(_temp_editor_path)
			if OS.has_feature("editor")
			else ProjectSettings.globalize_path(_temp_export_path))
var _temp_editor_path = "res://temp"
var _temp_export_path = "user://temp"

var database: GoboticsDB

func _init() -> void:
	database = GoboticsDB.new()
