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
		# Header Tags
		robot = Color.GREEN_YELLOW,
		standalone = Color.GREEN_YELLOW,
		env = Color.GREEN_YELLOW,
		# Standard Tags
		link = Color.ROYAL_BLUE,
		joint = Color.ROYAL_BLUE,
		material = Color.ROYAL_BLUE,
		sensor = Color.ROYAL_BLUE,
		gobotics = Color.ROYAL_BLUE,
		inertial = Color.ROYAL_BLUE,
		visual = Color.ROYAL_BLUE,
		collision = Color.ROYAL_BLUE,
	}
