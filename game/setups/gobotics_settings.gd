class_name GoboticsSettings extends Node
## Singleton GoboticsSettings
##
## Stocke la configuration du jeu Gobotics

## Chemin vers les projets utilisateur de Gobotics.
var projects_global_path: String = "res://examples"
var projects_export_path: String = "examples"

var asset_dir : String = "assets"
var asset_base_dir: String
var temp_path: String = "temp"

var database: GoboticsDB = GoboticsDB.new(temp_path)
