# Singleton BlocksDB
extends Node

var list = []

func _init():
	list.append(
		{
			name="Cube",
			path="res://game/blocks/generic/cube.tscn"
		}
	)

func get_block_path(block_name: String):
	for block in list:
		if block.name == block_name:
			return block.path
	return null
