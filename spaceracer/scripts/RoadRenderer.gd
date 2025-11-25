extends Node2D
class_name RoadRenderer

# Road rendering using pseudo-3D technique (Mode 7 / OutRun style)

# Rendering parameters
const ROAD_WIDTH: float = 2000.0  # Width of road in world units
const SEGMENT_LENGTH: float = 200.0  # Length of each segment
const DRAW_DISTANCE: float = 500  # How many segments to draw
const FOV: float = 100.0  # Field of view
const CAMERA_HEIGHT: float = 500.0  # Camera height above road
const CAMERA_DEPTH: float = 1 / CAMERA_HEIGHT  # For projection calculations

# Colors
const ROAD_COLOR_1: Color = Color(0.4, 0.4, 0.4)  # Dark asphalt
const ROAD_COLOR_2: Color = Color(0.5, 0.5, 0.5)  # Light asphalt
const GRASS_COLOR: Color = Color(0.0, 0.6, 0.0)  # Grass
const RUMBLE_COLOR_1: Color = Color(1.0, 1.0, 1.0)  # White rumble strip
const RUMBLE_COLOR_2: Color = Color(1.0, 0.0, 0.0)  # Red rumble strip
const LINE_COLOR: Color = Color(1.0, 1.0, 1.0)  # Center line

# Parallax colors
const SKY_COLOR: Color = Color(0.5, 0.7, 1.0)
const MOUNTAIN_COLOR_1: Color = Color(0.4, 0.3, 0.5)  # Distant mountains
const MOUNTAIN_COLOR_2: Color = Color(0.5, 0.4, 0.6)  # Mid mountains
const HILL_COLOR: Color = Color(0.2, 0.5, 0.2)  # Near hills

# Road segments
var segments: Array[RoadSegment] = []
var track_length: float = 0.0

# Traffic
var traffic_cars: Array[TrafficCar] = []

# Reference to player
var player: Player

func _ready():
	# Create the track
	create_track()
	
	# Spawn initial traffic
	spawn_traffic()

func create_track() -> void:
	# Create a looping track with various curves and hills
	segments.clear()
	
	var z_pos: float = 0.0
	var y_pos: float = 0.0
	var num_segments: int = 1500  # Total segments in track
	
	# Build segments with curves and hills
	for i in range(num_segments):
		var segment = RoadSegment.new()
		segment.z = z_pos
		segment.y = y_pos
		
		# Create varied track sections
		var progress: float = float(i) / float(num_segments)
		
		# Curves - create longer sections
		if progress < 0.3:  # Long straight
			segment.curve = 0.0
		elif progress < 0.45:  # Long right curve
			segment.curve = 1.2
		elif progress < 0.6:  # Long straight
			segment.curve = 0.0
		elif progress < 0.75:  # Long left curve
			segment.curve = -1.2
		elif progress < 0.85:  # S-curve
			if progress < 0.8:
				segment.curve = 1.05
			else:
				segment.curve = -1.05
		else:  # Final straight
			segment.curve = 0.0
		
		# Hills - add elevation changes
		if progress < 0.1:
			y_pos += 10.0   # Uphill
		elif progress < 0.2:
			y_pos -= 5.0   # Slight downhill
		elif progress < 0.4:
			y_pos += 0.0  # Flat
		elif progress < 0.45:
			y_pos += 50.0   # Big hill
		elif progress < 0.55:
			y_pos -= 30.0   # Down the hill
		elif progress < 0.8:
			y_pos += 2.0   # Slight uphill
		else:
			y_pos -= 2.0  # Back to start level
		
		segment.y = y_pos
		
		# Hills - add elevation changes
		var hill_position: float = float(i) / float(num_segments) * PI * 4.0
		y_pos = sin(hill_position) * 500.0 + cos(hill_position * 0.5) * 200.0
		
		# Alternate colors for road stripes
		segment.is_striped = (i % 4) < 2
		
		# Add roadside sprites periodically
		if i % 20 == 0:  # Every 20 segments
			# Add sprites on both sides
			var sprite_type = randi() % RoadsideSprite.SpriteType.size()
			
			# Left side
			var left_sprite = RoadsideSprite.new(-1.5 - randf() * 0.5, 0.0, sprite_type)
			segment.sprites.append(left_sprite)
			
			# Right side
			var right_sprite = RoadsideSprite.new(1.5 + randf() * 0.5, 0.0, sprite_type)
			segment.sprites.append(right_sprite)
		
		# Occasional single sprites
		if i % 10 == 5:
			var sprite_type = randi() % RoadsideSprite.SpriteType.size()
			var side = 1 if randf() > 0.5 else -1
			var sprite = RoadsideSprite.new(side * (1.5 + randf() * 0.5), 0.0, sprite_type)
			segment.sprites.append(sprite)
		
		segments.append(segment)
		z_pos += SEGMENT_LENGTH
	
	track_length = z_pos
	print("Track created with ", segments.size(), " segments, length: ", track_length)

func spawn_traffic() -> void:
	# Spawn some traffic cars
	traffic_cars.clear()
	
	# Spawn traffic cars at various positions
	for i in range(20):
		var z = randf() * track_length
		var x_lane = [-0.5, 0.0, 0.5][randi() % 3]  # Three lanes
		var speed = randf_range(200.0, 500.0)
		var oncoming = randf() > 0.7  # 30% chance of oncoming traffic
		
		if oncoming:
			speed = -speed  # Negative speed for oncoming
		
		var car = TrafficCar.new(z, x_lane, speed, oncoming)
		traffic_cars.append(car)

func get_curve_offset_at_segment(segment_index: int) -> float:
	var offset: float = 0.0
	var delta: float = 0.0
	for i in range(segment_index):
		delta += segments[i].curve
		offset += delta
	return offset

func draw_parallax_background(screen_width: float, screen_height: float, heading: float) -> void:
	# Draw sky
	draw_rect(Rect2(0, 0, screen_width, screen_height), SKY_COLOR)
	
	# heading represents the compass direction the player is facing
	# Positive heading = turned right, negative = turned left
	# Scale to pixels: small values so 30-degree turn = ~200px shift
	
	# Draw distant mountains (slowest parallax)
	var mountain_offset_1 = -heading * 1.5  # Negative so right turn shifts left
	mountain_offset_1 = fmod(mountain_offset_1 + screen_width * 10, screen_width * 2) - screen_width
	
	for i in range(-1, 3):
		var x_base = i * screen_width + mountain_offset_1
		# Simple mountain shapes using triangles
		var points_1 = PackedVector2Array([
			Vector2(x_base, screen_height * 0.4),
			Vector2(x_base + screen_width * 0.3, screen_height * 0.1),
			Vector2(x_base + screen_width * 0.6, screen_height * 0.4)
		])
		draw_colored_polygon(points_1, MOUNTAIN_COLOR_1)
	
	# Draw mid-distance mountains (medium parallax)
	var mountain_offset_2 = -heading * 3.0
	mountain_offset_2 = fmod(mountain_offset_2 + screen_width * 10, screen_width * 2) - screen_width
	
	for i in range(-1, 3):
		var x_base = i * screen_width + mountain_offset_2
		var points_2 = PackedVector2Array([
			Vector2(x_base + screen_width * 0.1, screen_height * 0.45),
			Vector2(x_base + screen_width * 0.35, screen_height * 0.15),
			Vector2(x_base + screen_width * 0.5, screen_height * 0.45)
		])
		draw_colored_polygon(points_2, MOUNTAIN_COLOR_2)
	
	# Draw near hills (faster parallax)
	var hill_offset = -heading * 6.0
	hill_offset = fmod(hill_offset + screen_width * 10, screen_width * 2) - screen_width
	
	for i in range(-1, 3):
		var x_base = i * screen_width + hill_offset
		draw_rect(Rect2(x_base, screen_height * 0.5, screen_width * 0.4, screen_height * 0.1), HILL_COLOR)

func _draw():
	if not player:
		return
	
	# Get screen dimensions
	var screen_width: float = get_viewport_rect().size.x
	var screen_height: float = get_viewport_rect().size.y
	var half_width: float = screen_width / 2.0
	var half_height: float = screen_height / 2.0
	
	# Find base segment (where player is)
	var base_index: int = player.get_segment_index(segments, track_length)
	var base_segment: RoadSegment = segments[base_index]
	
	# Calculate projection for visible segments
	var base_percent: float = fmod(player.position, SEGMENT_LENGTH) / SEGMENT_LENGTH
	
	var max_y: float = screen_height
	var curve_offset: float = 0.0
	var curve_delta: float = 0.0  # This tracks accumulated curve rate
	
	# Calculate player's current heading (compass direction) for parallax
	# Start from base_index and accumulate curve to get current facing direction
	var player_heading: float = 0.0
	for i in range(base_index + 1):
		player_heading += segments[i % segments.size()].curve
	
	# Add partial progress through current segment
	if base_index >= 0 and base_index < segments.size():
		player_heading += segments[base_index].curve * base_percent
	
	# Draw parallax background first - heading represents compass direction
	draw_parallax_background(screen_width, screen_height, player_heading)
	
	# Collect sprites to draw (for depth sorting)
	var sprites_to_draw: Array = []
	
	# Draw segments from far to near
	var draw_start: int = base_index
	var draw_end: int = base_index + int(DRAW_DISTANCE)
	
	for n in range(draw_start, draw_end):
		var i: int = n % segments.size()
		var segment: RoadSegment = segments[i]
		var next_segment: RoadSegment = segments[(i + 1) % segments.size()]

		# Interpolate to next segment for smoother visuals
		var lerp_amount: float = base_percent if i == base_index else 0.0
		var interpolated_y: float = lerp(segment.y, next_segment.y, lerp_amount)
		var interpolated_curve: float = lerp(segment.curve, next_segment.curve, lerp_amount)
		
		# Calculate distance from camera
		var segment_distance: float = float(n - base_index)
		var z: float = ((segment_distance + 1.0) - base_percent) * SEGMENT_LENGTH
		
		# Skip if too close
		if z < SEGMENT_LENGTH * 0.5:
			continue
		
		# 3D to 2D projection
		segment.scale = 300 / z 
		var camera_y: float = player.y + base_segment.y
		var proj_y: float = (camera_y - interpolated_y) * segment.scale
		segment.clip = half_height + proj_y
		
		# Skip segments that are off-screen (above horizon)
		if segment.clip >= max_y:
			continue
		
		# Calculate curve offset
		curve_delta += interpolated_curve
		curve_offset += curve_delta
		
		# Project road width and position
		var road_width: float = ROAD_WIDTH * segment.scale
		var x_offset: float = (curve_offset - (player.camera_x * ROAD_WIDTH)) * segment.scale
		
		var x1: float = half_width + x_offset - road_width
		var x2: float = half_width + x_offset + road_width
		var y1: float = segment.clip
		var y2: float = max_y
		
		# Ensure we're drawing something visible
		if y2 - y1 < 0.1:
			continue
		
		# Draw grass (background) - full width
		draw_rect(Rect2(0, y1, screen_width, y2 - y1), GRASS_COLOR)
		
		# Choose road color
		var road_color: Color = ROAD_COLOR_1 if segment.is_striped else ROAD_COLOR_2
		var rumble_color: Color = RUMBLE_COLOR_1 if segment.is_striped else RUMBLE_COLOR_2
		
		# Draw rumble strips (road edges)
		var rumble_width: float = road_width * 0.15
		draw_rect(Rect2(x1 - rumble_width, y1, rumble_width, y2 - y1), rumble_color)
		draw_rect(Rect2(x2, y1, rumble_width, y2 - y1), rumble_color)
		
		# Draw road surface
		draw_rect(Rect2(x1, y1, road_width * 2.0, y2 - y1), road_color)
		
		# Draw center line (on striped segments only)
		if segment.is_striped:
			var line_width: float = road_width * 0.05
			draw_rect(Rect2(half_width + x_offset - line_width, y1, 
							line_width * 2.0, y2 - y1), LINE_COLOR)
		
		# Collect roadside sprites for this segment
		for sprite in segment.sprites:
			var sprite_data = {
				"sprite": sprite,
				"segment": segment,
				"x_offset": x_offset,
				"z": z,
				"scale": segment.scale
			}
			sprites_to_draw.append(sprite_data)
		
		max_y = y1
	
	# Draw roadside sprites (sorted by distance, far to near)
	for sprite_data in sprites_to_draw:
		draw_roadside_sprite(sprite_data, half_width, curve_offset)
	
	# Draw traffic cars
	draw_traffic(half_width, half_height, base_index, base_percent, curve_offset)
	
	# Draw player car (simple rectangle for now)
	draw_player_car(screen_width, screen_height)
	
	# Draw simple HUD
	draw_hud(screen_width, screen_height)

func draw_roadside_sprite(sprite_data: Dictionary, half_width: float, curve_offset: float) -> void:
	var sprite: RoadsideSprite = sprite_data["sprite"]
	var segment: RoadSegment = sprite_data["segment"]
	var x_offset: float = sprite_data["x_offset"]
	var scale: float = sprite_data["scale"]
	
	# Project sprite position
	var sprite_x: float = half_width + x_offset + (sprite.x * ROAD_WIDTH * scale)
	var sprite_y: float = segment.clip - (sprite.height * scale)
	var sprite_width: float = sprite.width * scale
	var sprite_height: float = sprite.height * scale
	
	# Only draw if on screen
	var screen_width = get_viewport_rect().size.x
	if sprite_x > -sprite_width and sprite_x < screen_width + sprite_width:
		# Draw sprite as colored rectangle (placeholder)
		draw_rect(Rect2(sprite_x - sprite_width / 2, sprite_y, sprite_width, sprite_height), sprite.color)
		
		# Add outline for visibility
		draw_rect(Rect2(sprite_x - sprite_width / 2, sprite_y, sprite_width, sprite_height), 
				  Color(0, 0, 0), false, max(1.0, scale))

func draw_traffic(half_width: float, half_height: float, base_index: int, base_percent: float, curve_offset: float) -> void:
	# Draw all traffic cars
	for car in traffic_cars:
		# Calculate which segment this car is on
		var car_segment_idx = -1
		var wrapped_pos = fmod(car.position, track_length)
		if wrapped_pos < 0:
			wrapped_pos += track_length
		
		for i in range(segments.size()):
			if segments[i].z > wrapped_pos:
				car_segment_idx = max(0, i - 1)
				break
		
		if car_segment_idx == -1:
			car_segment_idx = segments.size() - 1
		
		# Only draw if within view distance
		var distance_from_player = car_segment_idx - base_index
		if distance_from_player < 0:
			distance_from_player += segments.size()
		
		if distance_from_player > DRAW_DISTANCE or distance_from_player < 1:
			continue
		
		var car_segment: RoadSegment = segments[car_segment_idx]
		var z: float = float(distance_from_player) * SEGMENT_LENGTH
		
		if z < SEGMENT_LENGTH * 0.5:
			continue
		
		# Project car position
		var scale = 300.0 / z
		var car_width = TrafficCar.CAR_WIDTH * scale
		var car_height = TrafficCar.CAR_HEIGHT * scale
		
		var car_x_offset = (curve_offset - (player.camera_x * ROAD_WIDTH)) * scale
		var car_x = half_width + car_x_offset + (car.x * ROAD_WIDTH * scale)
		var car_y = car_segment.clip - car_height
		
		# Draw car as colored rectangle (placeholder)
		draw_rect(Rect2(car_x - car_width / 2, car_y, car_width, car_height), car.color)
		
		# Add windows
		var window_color = Color(0.1, 0.1, 0.3)
		draw_rect(Rect2(car_x - car_width / 2 + car_width * 0.1, car_y + car_height * 0.1, 
						car_width * 0.8, car_height * 0.3), window_color)
		
		# Add headlights/taillights
		var light_color = Color(1.0, 1.0, 0.0) if car.is_oncoming else Color(1.0, 0.0, 0.0)
		var light_size = car_width * 0.15
		var light_y = car_y + (car_height * 0.8 if car.is_oncoming else car_height * 0.05)
		draw_rect(Rect2(car_x - car_width / 2 + car_width * 0.15, light_y, light_size, light_size * 0.5), light_color)
		draw_rect(Rect2(car_x + car_width / 2 - car_width * 0.15 - light_size, light_y, light_size, light_size * 0.5), light_color)

func draw_player_car(screen_width: float, screen_height: float) -> void:
	# Draw a simple car sprite at bottom center
	var car_width: float = 80.0
	var car_height: float = 100.0
	var car_x: float = (screen_width / 2.0) - (car_width / 2.0)
	var car_y: float = screen_height - car_height - 50.0
	
	# Car body (red)
	draw_rect(Rect2(car_x, car_y, car_width, car_height), Color(0.8, 0.1, 0.1))
	
	# Car windows (dark blue)
	draw_rect(Rect2(car_x + 10, car_y + 10, car_width - 20, 30), Color(0.1, 0.1, 0.3))
	
	# Car wheels (black)
	draw_rect(Rect2(car_x - 5, car_y + 20, 10, 30), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(car_x + car_width - 5, car_y + 20, 10, 30), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(car_x - 5, car_y + 60, 10, 30), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(car_x + car_width - 5, car_y + 60, 10, 30), Color(0.1, 0.1, 0.1))

func draw_hud(screen_width: float, screen_height: float) -> void:
	# Draw simple speed indicator
	var speed_text: String = "Speed: %d" % int(player.speed)
	var position_text: String = "Position: %d" % int(player.position)
	
	# Background for HUD
	draw_rect(Rect2(10, 10, 200, 60), Color(0, 0, 0, 0.5))
	
	# Note: In a real implementation, you'd use Label nodes or draw_string
	# For now, we'll just draw colored rectangles as placeholders
	# The actual text would need a font resource
	
	# Speed bar
	var speed_percentage: float = player.speed / Player.MAX_SPEED
	draw_rect(Rect2(20, 20, 180 * speed_percentage, 15), Color(0.0, 1.0, 0.0))
	draw_rect(Rect2(20, 20, 180, 15), Color(1.0, 1.0, 1.0), false, 2.0)
	
	# Position indicator (lap progress)
	var lap_percentage: float = fmod(player.position, track_length) / track_length
	draw_rect(Rect2(20, 45, 180 * lap_percentage, 15), Color(0.0, 0.5, 1.0))
	draw_rect(Rect2(20, 45, 180, 15), Color(1.0, 1.0, 1.0), false, 2.0)

func _process(delta: float) -> void:
	# Update traffic
	for car in traffic_cars:
		car.update(delta, track_length)
	
	queue_redraw()  # Continuously redraw
