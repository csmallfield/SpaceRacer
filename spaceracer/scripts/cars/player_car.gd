class_name PlayerCar
extends Node2D
## PlayerCar - Player-controlled vehicle with pseudo-3D physics

signal speed_changed(speed: float, max_speed: float)
signal position_changed(x: float, z: float)

# Physics constants
const MAX_SPEED: float = 300.0  # Max speed in units per second
const ACCELERATION: float = 150.0
const BRAKING: float = 200.0
const DECELERATION: float = 50.0  # Natural deceleration
const OFF_ROAD_DECEL: float = 150.0  # Extra deceleration when off road
const OFF_ROAD_MAX_SPEED: float = 100.0  # Speed limit when off road

const STEERING_SPEED: float = 3.0
const MAX_STEERING: float = 1.0
const STEERING_RETURN_SPEED: float = 5.0

const CENTRIFUGAL_FORCE: float = 0.3  # How much curves push the car

# Car state
var speed: float = 0.0
var world_x: float = 0.0  # Horizontal position on road
var world_z: float = 0.0  # Position along track
var steering: float = 0.0  # Current steering amount (-1 to 1)

# Reference to road and track
var road_renderer: RoadRenderer = null
var track: Track = null

# Visual settings
var car_width: float = 80.0
var car_height: float = 50.0
var car_color: Color = Color(0.8, 0.2, 0.2)

# Screen position (car is always drawn at fixed screen position)
var screen_y: float = 480.0  # Near bottom of screen
var screen_x: float = 480.0  # Center of screen

# Car ID for game manager
var car_id: int = 0

# Bounce effect for off-road
var bounce_offset: float = 0.0
var bounce_timer: float = 0.0

func _ready() -> void:
	screen_x = 960.0 / 2.0
	GameManager.register_car(car_id, true)

func setup(renderer: RoadRenderer, game_track: Track) -> void:
	road_renderer = renderer
	track = game_track
	world_z = 0.0
	world_x = 0.0
	speed = 0.0

func _process(delta: float) -> void:
	if GameManager.race_state != GameManager.RaceState.RACING:
		return
	
	_handle_input(delta)
	_update_physics(delta)
	_update_game_manager()
	queue_redraw()

func _handle_input(delta: float) -> void:
	# Acceleration / Braking
	if Input.is_action_pressed("accelerate"):
		speed += ACCELERATION * delta
	elif Input.is_action_pressed("brake"):
		speed -= BRAKING * delta
	else:
		# Natural deceleration
		speed -= DECELERATION * delta
	
	# Steering
	var steer_input = 0.0
	if Input.is_action_pressed("steer_left"):
		steer_input = -1.0
	elif Input.is_action_pressed("steer_right"):
		steer_input = 1.0
	
	if steer_input != 0:
		steering = move_toward(steering, steer_input * MAX_STEERING, STEERING_SPEED * delta)
	else:
		steering = move_toward(steering, 0.0, STEERING_RETURN_SPEED * delta)

func _update_physics(delta: float) -> void:
	# Check if off road
	var off_road = road_renderer.is_off_road(world_x) if road_renderer else false
	
	if off_road:
		# Extra deceleration off road
		speed -= OFF_ROAD_DECEL * delta
		speed = min(speed, OFF_ROAD_MAX_SPEED)
		
		# Bounce effect
		bounce_timer += delta * 20.0
		bounce_offset = sin(bounce_timer) * 5.0
	else:
		bounce_offset = 0.0
		bounce_timer = 0.0
	
	# Clamp speed
	speed = clamp(speed, 0.0, MAX_SPEED)
	
	# Move along track
	world_z += speed * delta
	
	# Wrap around track
	if track:
		world_z = fmod(world_z, track.track_length)
		if world_z < 0:
			world_z += track.track_length
	
	# Apply steering (scaled by speed)
	var speed_percent = speed / MAX_SPEED
	world_x += steering * STEERING_SPEED * speed_percent * 100.0 * delta
	
	# Apply centrifugal force from curves
	if track and road_renderer:
		var segment = track.get_segment_at_z(world_z)
		if segment:
			world_x += segment.curve * CENTRIFUGAL_FORCE * speed_percent * speed_percent * 100.0 * delta
	
	# Clamp horizontal position
	var max_x = 2000.0  # Allow some off-road travel
	world_x = clamp(world_x, -max_x, max_x)
	
	# Update camera
	if road_renderer:
		road_renderer.update_camera(world_z, world_x)
	
	# Emit signals
	speed_changed.emit(speed, MAX_SPEED)
	position_changed.emit(world_x, world_z)

func _update_game_manager() -> void:
	if track:
		var track_position = track.get_position_percent(world_z)
		GameManager.update_car_position(car_id, track_position)

func _draw() -> void:
	# Draw the player car at fixed screen position
	var draw_x = screen_x
	var draw_y = screen_y + bounce_offset
	
	# Car body (simple rectangle placeholder)
	var car_rect = Rect2(
		draw_x - car_width / 2.0,
		draw_y - car_height,
		car_width,
		car_height
	)
	
	# Tilt car based on steering
	var tilt = steering * 5.0
	
	# Draw shadow
	var shadow_rect = Rect2(
		car_rect.position.x + 5,
		car_rect.position.y + car_height - 10,
		car_width,
		15
	)
	draw_rect(shadow_rect, Color(0, 0, 0, 0.3))
	
	# Draw car body with steering tilt effect
	_draw_tilted_car(draw_x, draw_y, tilt)

func _draw_tilted_car(center_x: float, base_y: float, tilt: float) -> void:
	var half_width = car_width / 2.0
	var height = car_height
	
	# Calculate tilted corners
	var top_left = Vector2(center_x - half_width + tilt, base_y - height)
	var top_right = Vector2(center_x + half_width + tilt, base_y - height)
	var bottom_right = Vector2(center_x + half_width, base_y)
	var bottom_left = Vector2(center_x - half_width, base_y)
	
	# Main body
	var body_points = PackedVector2Array([top_left, top_right, bottom_right, bottom_left])
	draw_colored_polygon(body_points, car_color)
	
	# Windshield
	var windshield_color = Color(0.6, 0.8, 1.0, 0.8)
	var ws_top_left = Vector2(center_x - half_width * 0.6 + tilt * 0.8, base_y - height * 0.85)
	var ws_top_right = Vector2(center_x + half_width * 0.6 + tilt * 0.8, base_y - height * 0.85)
	var ws_bottom_right = Vector2(center_x + half_width * 0.7 + tilt * 0.5, base_y - height * 0.5)
	var ws_bottom_left = Vector2(center_x - half_width * 0.7 + tilt * 0.5, base_y - height * 0.5)
	var windshield_points = PackedVector2Array([ws_top_left, ws_top_right, ws_bottom_right, ws_bottom_left])
	draw_colored_polygon(windshield_points, windshield_color)
	
	# Wheels (simple rectangles)
	var wheel_color = Color(0.1, 0.1, 0.1)
	var wheel_width = 12.0
	var wheel_height = 20.0
	
	# Left wheel
	draw_rect(Rect2(bottom_left.x - wheel_width * 0.5, base_y - wheel_height, wheel_width, wheel_height), wheel_color)
	# Right wheel
	draw_rect(Rect2(bottom_right.x - wheel_width * 0.5, base_y - wheel_height, wheel_width, wheel_height), wheel_color)

func get_speed_mph() -> float:
	# Convert internal speed to MPH for display
	return speed * 0.6

func reset_position() -> void:
	world_z = 0.0
	world_x = 0.0
	speed = 0.0
	steering = 0.0
