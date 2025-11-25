extends RefCounted
class_name TrafficCar

# Traffic car data
# These are AI-controlled cars on the road

var position: float = 0.0  # Z position along track
var x: float = 0.0  # X position relative to road center (-1 to 1)
var speed: float = 0.0  # Current speed (negative for oncoming traffic)
var is_oncoming: bool = false  # True if traveling toward player
var color: Color = Color.WHITE  # Car color

# Visual properties
const CAR_WIDTH: float = 80.0
const CAR_HEIGHT: float = 100.0

func _init(z_pos: float = 0.0, x_pos: float = 0.0, car_speed: float = 0.0, oncoming: bool = false):
	position = z_pos
	x = x_pos
	speed = car_speed
	is_oncoming = oncoming
	
	# Random color for variety
	var colors = [
		Color(0.8, 0.1, 0.1),  # Red
		Color(0.1, 0.1, 0.8),  # Blue
		Color(1.0, 1.0, 0.0),  # Yellow
		Color(0.9, 0.9, 0.9),  # White
		Color(0.1, 0.1, 0.1),  # Black
		Color(0.0, 0.7, 0.0),  # Green
	]
	color = colors[randi() % colors.size()]

func update(delta: float, track_length: float) -> void:
	# Update position
	if is_oncoming:
		position -= speed * delta * 10.0
	else:
		position += speed * delta * 10.0
	
	# Wrap around track
	if position < 0:
		position += track_length
	elif position >= track_length:
		position = fmod(position, track_length)
