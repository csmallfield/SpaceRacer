class_name AICar
extends Node2D
## AICar - AI-controlled opponent vehicle

# AI difficulty settings
enum Difficulty { EASY, MEDIUM, HARD }

@export var difficulty: Difficulty = Difficulty.MEDIUM
@export var car_color: Color = Color(0.2, 0.2, 0.8)

# Physics constants (vary by difficulty)
var max_speed: float = 250.0
var acceleration: float = 100.0
var steering_skill: float = 0.8  # How well AI follows curves

# Car state
var speed: float = 0.0
var world_x: float = 0.0
var world_z: float = 0.0
var target_x: float = 0.0  # Target horizontal position

# Reference to track
var track: Track = null
var road_renderer: RoadRenderer = null

# Visual settings
var car_width: float = 70.0
var car_height: float = 45.0

# Car ID
var car_id: int = 1

# Projected screen position (calculated during render)
var screen_x: float = 0.0
var screen_y: float = 0.0
var screen_scale: float = 1.0
var is_visible: bool = false

# Random variation
var speed_variation: float = 0.0
var lane_preference: float = 0.0  # -1 to 1, which side of road AI prefers

func _ready() -> void:
	_apply_difficulty()
	GameManager.register_car(car_id, false)
	
	# Add some randomness
	speed_variation = randf_range(-20.0, 20.0)
	lane_preference = randf_range(-0.3, 0.3)

func _apply_difficulty() -> void:
	match difficulty:
		Difficulty.EASY:
			max_speed = 200.0 + randf_range(-10, 10)
			acceleration = 80.0
			steering_skill = 0.6
		Difficulty.MEDIUM:
			max_speed = 250.0 + randf_range(-15, 15)
			acceleration = 100.0
			steering_skill = 0.8
		Difficulty.HARD:
			max_speed = 290.0 + randf_range(-10, 10)
			acceleration = 120.0
			steering_skill = 0.95

func setup(renderer: RoadRenderer, game_track: Track, start_z: float, start_x: float = 0.0) -> void:
	road_renderer = renderer
	track = game_track
	world_z = start_z
	world_x = start_x

func _process(delta: float) -> void:
	if GameManager.race_state != GameManager.RaceState.RACING:
		return
	
	_update_ai(delta)
	_update_physics(delta)
	_update_game_manager()
	_update_screen_position()
	queue_redraw()

func _update_ai(delta: float) -> void:
	if not track:
		return
	
	# Get current and upcoming segments for lookahead
	var segment = track.get_segment_at_z(world_z)
	var lookahead_z = world_z + speed * 0.5  # Look ahead based on speed
	var lookahead_segment = track.get_segment_at_z(lookahead_z)
	
	if not segment:
		return
	
	# Calculate target X based on upcoming curve
	var curve = 0.0
	if lookahead_segment:
		curve = lookahead_segment.curve
	
	# AI tries to position towards inside of curve
	target_x = -curve * steering_skill * 400.0
	target_x += lane_preference * 300.0  # Add lane preference
	
	# Clamp to road bounds with some margin
	var max_x = track.road_width * 0.4
	target_x = clamp(target_x, -max_x, max_x)
	
	# Speed adjustment for curves
	var curve_speed_factor = 1.0 - abs(curve) * 0.3
	var target_speed = (max_speed + speed_variation) * curve_speed_factor
	
	# Accelerate/decelerate towards target speed
	if speed < target_speed:
		speed += acceleration * delta
	else:
		speed -= acceleration * 0.5 * delta
	
	speed = clamp(speed, 0.0, max_speed + speed_variation)

func _update_physics(delta: float) -> void:
	# Move along track
	world_z += speed * delta
	
	# Wrap around track
	if track:
		world_z = fmod(world_z, track.track_length)
		if world_z < 0:
			world_z += track.track_length
	
	# Steer towards target X
	var steer_speed = 2.0 * steering_skill
	world_x = move_toward(world_x, target_x, steer_speed * speed * delta * 0.1)

func _update_game_manager() -> void:
	if track:
		var track_position = track.get_position_percent(world_z)
		GameManager.update_car_position(car_id, track_position)

func _update_screen_position() -> void:
	if not road_renderer:
		is_visible = false
		return
	
	# Calculate relative Z position from camera
	var camera_z = road_renderer.camera_z
	var camera_x = road_renderer.camera_x
	var relative_z = world_z - camera_z
	
	# Handle track wrapping
	if relative_z < -track.track_length / 2:
		relative_z += track.track_length
	elif relative_z > track.track_length / 2:
		relative_z -= track.track_length
	
	# Convert to segment units (same as road renderer)
	var z_segments = relative_z / road_renderer.SEGMENT_LENGTH
	
	# Only visible if in front of camera and within draw distance
	if z_segments < 0.5 or z_segments > road_renderer.draw_distance:
		is_visible = false
		return
	
	is_visible = true
	
	# Project to screen using same formula as road renderer
	screen_scale = 1.0 / z_segments
	screen_y = road_renderer.HORIZON_Y + (road_renderer.ROAD_SCALE * screen_scale)
	
	# Calculate X position relative to road
	var relative_x = world_x - camera_x
	screen_x = (960.0 / 2.0) + (relative_x * screen_scale * 0.3)

func _draw() -> void:
	if not is_visible:
		return
	
	# Scale car based on distance
	var scaled_width = car_width * screen_scale * 5.0
	var scaled_height = car_height * screen_scale * 5.0
	
	# Don't draw if too small or too large
	if scaled_width < 5 or scaled_width > 300:
		return
	
	# Draw shadow
	var shadow_rect = Rect2(
		screen_x - scaled_width / 2.0 + 3 * screen_scale,
		screen_y - scaled_height * 0.2,
		scaled_width,
		scaled_height * 0.3
	)
	draw_rect(shadow_rect, Color(0, 0, 0, 0.3))
	
	# Draw car body
	var car_rect = Rect2(
		screen_x - scaled_width / 2.0,
		screen_y - scaled_height,
		scaled_width,
		scaled_height
	)
	draw_rect(car_rect, car_color)
	
	# Draw windshield
	var windshield_color = Color(0.6, 0.8, 1.0, 0.8)
	var ws_rect = Rect2(
		screen_x - scaled_width * 0.3,
		screen_y - scaled_height * 0.85,
		scaled_width * 0.6,
		scaled_height * 0.35
	)
	draw_rect(ws_rect, windshield_color)
	
	# Draw wheels
	var wheel_color = Color(0.1, 0.1, 0.1)
	var wheel_width = scaled_width * 0.15
	var wheel_height = scaled_height * 0.4
	
	# Left wheel
	draw_rect(Rect2(
		screen_x - scaled_width / 2.0 - wheel_width * 0.3,
		screen_y - wheel_height,
		wheel_width,
		wheel_height
	), wheel_color)
	
	# Right wheel
	draw_rect(Rect2(
		screen_x + scaled_width / 2.0 - wheel_width * 0.7,
		screen_y - wheel_height,
		wheel_width,
		wheel_height
	), wheel_color)

func get_z_distance_from(other_z: float) -> float:
	var dist = world_z - other_z
	if track:
		# Handle wrapping
		if dist > track.track_length / 2:
			dist -= track.track_length
		elif dist < -track.track_length / 2:
			dist += track.track_length
	return dist
