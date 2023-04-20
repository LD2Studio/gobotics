# Singleton BlocksDB
extends Node

var list = [
	{
		name="GenoiseLayer",
		path="res://Cup2023/sponge_cake_layer.tscn",
		preview="res://Cup2023/SpongeCakeLayer.png"
	},
#	{
#		name="Robot Alpha",
#		path="res://robots/robot_alpha.tscn",
#		preview="res://robots/robot_alpha/RobotAlpha.png"
#	},
#	{
#		name="Robot Beta",
#		path="res://robots/robot_beta/robot_beta.tscn",
#		preview="res://robots/robot_beta/RobotBeta.png"
#	},
#	{
#		name="Robot Gamma",
#		path="res://robots/robot_gamma.tscn",
#		preview="res://robots/robot_beta/RobotBeta.png"
#	},
	{
		name="Sphere",
		path="res://Cup2023/ball.tscn",
		preview="res://Cup2023/Ball.png"
	}
]

func get_block_path(block_name: String):
	for block in list:
		if block.name == block_name:
			return block.path
	return null
	
func get_preview(item_name: String):
	for item in list:
		if item.name == item_name:
			if "preview" in item: return item.preview
			else: return null
	return null
