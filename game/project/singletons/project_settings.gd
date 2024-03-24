class_name GProjectSettings extends Node
## Singleton GProjectSettings
##
## Stocke les caractéristiques du projet en cours, comme ...

## Nom du fichier du projet en cours, avec l'extension [code].scene[/code]
var project_filename: String
var env_path: String
var is_new_project: bool


## Rapport d'échelle utilisé pour obtenir des dimensions d'objets compatibles
## avec le moteur de physique Jolt. Tous les objets physiques ont des dimensions
## qui sont multipliées par SCALE.
const SCALE : float = 10.0

var physics_tick: int = 0
