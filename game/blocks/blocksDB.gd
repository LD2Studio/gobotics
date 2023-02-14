# Singleton BlocksDB
extends Node

var list = [
	{
		name="Cube",
		path="res://game/blocks/generic/cube.tscn"
	},
	{
		name="Cylinder",
		path="res://game/blocks/generic/cylinder.tscn"
	},
	{
		name="GenoiseLayer",
		path="res://game/blocks/robotics_cup/sponge_cake_layer.tscn"
	},
]

func get_block_path(block_name: String):
	for block in list:
		if block.name == block_name:
			return block.path
	return null
