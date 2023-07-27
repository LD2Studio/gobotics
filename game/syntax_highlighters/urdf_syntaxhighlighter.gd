extends CodeHighlighter
class_name URDFSyntaxHighlighter

func _init():
	# Comments
	add_color_region("<!--", "-->", Color.DARK_GREEN)

	# Strings
	add_color_region("\"", "\"", Color.ORANGE)
	# Operators
	symbol_color = Color.SKY_BLUE
	# Numbers
	number_color = Color.LIGHT_YELLOW

	keyword_colors = {
		robot = Color.ROYAL_BLUE,
		asset = Color.ROYAL_BLUE,
		link = Color.ROYAL_BLUE,
		joint = Color.ROYAL_BLUE,
		material = Color.ROYAL_BLUE,
		gobotics = Color.ROYAL_BLUE,
		inertial = Color.ROYAL_BLUE,
		visual = Color.ROYAL_BLUE,
		collision = Color.ROYAL_BLUE,
	}
