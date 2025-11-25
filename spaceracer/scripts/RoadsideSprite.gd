extends RefCounted
class_name RoadsideSprite

# Roadside sprite/object data
# These are scenery objects placed along the sides of the road

var x: float = 0.0  # X offset from road center (negative = left, positive = right)
var y: float = 0.0  # Y offset (height above road surface)
var width: float = 100.0  # Visual width
var height: float = 100.0  # Visual height
var color: Color = Color.GREEN  # Placeholder color

enum SpriteType {
	TREE,
	ROCK,
	SIGN,
	BUILDING,
	BILLBOARD
}

var sprite_type: SpriteType = SpriteType.TREE

func _init(x_pos: float = 0.0, y_pos: float = 0.0, type: SpriteType = SpriteType.TREE):
	x = x_pos
	y = y_pos
	sprite_type = type
	
	# Set properties based on type
	match sprite_type:
		SpriteType.TREE:
			width = 80.0
			height = 150.0
			color = Color(0.0, 0.5, 0.0)  # Dark green
		SpriteType.ROCK:
			width = 60.0
			height = 60.0
			color = Color(0.5, 0.5, 0.5)  # Gray
		SpriteType.SIGN:
			width = 50.0
			height = 100.0
			color = Color(1.0, 1.0, 0.0)  # Yellow
		SpriteType.BUILDING:
			width = 200.0
			height = 300.0
			color = Color(0.6, 0.6, 0.7)  # Light gray
		SpriteType.BILLBOARD:
			width = 150.0
			height = 100.0
			color = Color(1.0, 0.5, 0.0)  # Orange
