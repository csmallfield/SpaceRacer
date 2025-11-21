extends RefCounted
class_name RoadSegment

# Road segment data structure
# Each segment represents a slice of the road with curve and height information

var z: float = 0.0  # Z position (distance from camera start)
var y: float = 0.0  # World Y position (height)
var curve: float = 0.0  # Curve amount (dx) - positive = right, negative = left
var clip: float = 0.0  # Screen Y position where this segment should clip
var scale: float = 0.0  # Scale factor for this segment (1/z adjusted)

# Visual properties
var color: Color = Color.WHITE
var is_striped: bool = false  # For alternating road colors

func _init(z_pos: float = 0.0, y_pos: float = 0.0, curve_amount: float = 0.0):
	z = z_pos
	y = y_pos
	curve = curve_amount
