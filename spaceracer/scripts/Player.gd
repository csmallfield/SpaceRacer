extends Node
class_name Player

# Player state and movement
var position: float = 1000.0  # Position along the track (Z coordinate)
var speed: float = 0.0  # Current speed
var x: float = 0.0  # X position relative to road center (-1 to 1, where 0 is center)
var y: float = 0.0  # Y position (camera height above ground)

# Movement parameters
const MAX_SPEED: float = 800.0
const ACCELERATION: float = 200.0
const DECELERATION: float = 300.0
const BRAKE_DECELERATION: float = 150.0
const OFF_ROAD_DECEL: float = 00.0
const STEERING_SPEED: float = 20.0
const CENTRIFUGAL_FORCE: float = 0.3

# Camera
const CAMERA_HEIGHT: float = 1000.0  # Camera height above road
const CAMERA_DEPTH: float = 1.0 / CAMERA_HEIGHT  # For projection calculations

func _init():
	y = CAMERA_HEIGHT

func update(delta: float, current_segment: RoadSegment) -> void:
	# Handle acceleration/braking
	if Input.is_action_pressed("accelerate"):
		speed += ACCELERATION * delta
	elif Input.is_action_pressed("brake"):
		speed -= BRAKE_DECELERATION * delta
	else:
		speed -= DECELERATION * delta
	
	# Clamp speed
	speed = clampf(speed, 0.0, MAX_SPEED)
	
	# Handle steering
	var steering: float = 0.0
	if Input.is_action_pressed("steer_left"):
		steering = -1.0
	elif Input.is_action_pressed("steer_right"):
		steering = 1.0
	
	# Apply centrifugal force from curves
	if current_segment:
		x -= (current_segment.curve * speed * CENTRIFUGAL_FORCE * delta)
	
	# Apply steering
	x += steering * STEERING_SPEED * delta
	
	# Keep player on or near the road (allow going off-road but slow down)
	if abs(x) > 1.0:
		# Off-road - apply additional deceleration
		speed -= OFF_ROAD_DECEL * delta
		speed = maxf(speed, 0.0)
		# Limit how far off-road you can go
		x = clampf(x, -2.0, 2.0)
	
	# Update position along track
	position += speed * delta * 10.0
	print("Speed: ", speed, " Position: ", position)  # Debug line

func get_segment_index(segments: Array, track_length: float) -> int:
	# Wrap position around track
	var wrapped_pos = fmod(position, track_length)
	if wrapped_pos < 0:
		wrapped_pos += track_length
	
	# Find which segment we're on
	for i in range(segments.size()):
		if segments[i].z > wrapped_pos:
			return max(0, i - 1)
	
	return segments.size() - 1
