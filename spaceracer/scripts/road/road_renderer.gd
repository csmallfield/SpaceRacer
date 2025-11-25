class_name RoadRenderer
extends Node2D
## RoadRenderer - Core pseudo-3D road rendering using projected segments
## Based on techniques from Lou's Pseudo 3D Page

# Screen/rendering settings
const SCREEN_WIDTH: int = 960
const SCREEN_HEIGHT: int = 540
const ROAD_Y: int = 540  # Bottom of screen where road starts
const HORIZON_Y: int = 220  # Where the road meets the horizon

# Camera/projection settings
var camera_height: float = 1000.0  # Height above road
var camera_depth: float = 0.84  # Camera depth (affects FOV)
var draw_distance: int = 300  # Number of segments to draw
var fog_density: float = 5.0  # Exponential fog factor

# Road segment settings
const SEGMENT_LENGTH: float = 200.0  # Length of each segment in world units
const RUMBLE_LENGTH: int = 3  # Segments per rumble strip alternation

# Current state
var track: Track = null
var camera_z: float = 0.0  # Current position along track
var camera_x: float = 0.0  # Horizontal offset (steering)

# Projection cache
var projected_segments: Array = []  # Cache of projected segment data

# Sprites to render (sorted by Z for painter's algorithm)
var sprite_render_queue: Array = []

# Reference to sprite textures (placeholder rectangles for now)
var sprite_textures: Dictionary = {}

func _ready() -> void:
	_create_placeholder_sprites()

func _create_placeholder_sprites() -> void:
	# Create simple placeholder textures for roadside objects
	var tree_img = Image.create(32, 64, false, Image.FORMAT_RGBA8)
	tree_img.fill(Color(0.2, 0.5, 0.2))
	var tree_tex = ImageTexture.create_from_image(tree_img)
	sprite_textures["tree"] = tree_tex
	
	var rock_img = Image.create(40, 30, false, Image.FORMAT_RGBA8)
	rock_img.fill(Color(0.5, 0.5, 0.5))
	var rock_tex = ImageTexture.create_from_image(rock_img)
	sprite_textures["rock"] = rock_tex
	
	var sign_img = Image.create(24, 48, false, Image.FORMAT_RGBA8)
	sign_img.fill(Color(0.8, 0.8, 0.0))
	var sign_tex = ImageTexture.create_from_image(sign_img)
	sprite_textures["sign"] = sign_tex
	
	var building_img = Image.create(80, 100, false, Image.FORMAT_RGBA8)
	building_img.fill(Color(0.6, 0.4, 0.3))
	var building_tex = ImageTexture.create_from_image(building_img)
	sprite_textures["building"] = building_tex

func set_track(new_track: Track) -> void:
	track = new_track

func update_camera(z: float, x: float) -> void:
	camera_z = z
	camera_x = x
	queue_redraw()

func _draw() -> void:
	if not track or track.segments.size() == 0:
		return
	
	# Draw sky gradient
	_draw_sky()
	
	# Project and draw road segments
	_project_segments()
	_draw_road()
	
	# Draw roadside sprites (back to front)
	_draw_sprites()

func _draw_sky() -> void:
	# Sky gradient from top to horizon
	var sky_rect = Rect2(0, 0, SCREEN_WIDTH, HORIZON_Y)
	draw_rect(sky_rect, track.sky_color)
	
	# Horizon band
	var horizon_rect = Rect2(0, HORIZON_Y - 20, SCREEN_WIDTH, 40)
	draw_rect(horizon_rect, track.horizon_color)

func _project_segments() -> void:
	projected_segments.clear()
	sprite_render_queue.clear()
	
	var base_segment_index = int(camera_z / SEGMENT_LENGTH) % track.segments.size()
	var segment_percent = fmod(camera_z, SEGMENT_LENGTH) / SEGMENT_LENGTH
	
	var max_y = ROAD_Y
	
	# Curve accumulation variables (from Lou's tutorial)
	var x = 0.0      # Current X offset
	var dx = 0.0     # Curve velocity
	
	# Hill accumulation
	var y_offset = 0.0
	var dy = 0.0     # Hill velocity
	
	# Initialize dx based on segment percent to keep curve consistent during scrolling
	# This is Jake's fix from codeincomplete.com
	var base_segment = track.segments[base_segment_index]
	dx = -segment_percent * base_segment.curve * SEGMENT_LENGTH * 0.001
	dy = -segment_percent * base_segment.hill * SEGMENT_LENGTH * 0.0005
	
	for i in range(draw_distance):
		var segment_index = (base_segment_index + i) % track.segments.size()
		var segment = track.segments[segment_index]
		
		# Calculate Z distance from camera
		var z_distance = (i * SEGMENT_LENGTH) - fmod(camera_z, SEGMENT_LENGTH) + SEGMENT_LENGTH
		
		if z_distance <= camera_depth:
			continue
		
		# Project to screen using perspective formula
		var scale = camera_depth / z_distance
		
		# Base Y position (flat road)
		var projected_y = HORIZON_Y + (camera_height * scale) + y_offset
		
		# Road width at this depth
		var projected_width = track.road_width * scale
		
		# X position with camera offset and curve accumulation
		var projected_x = (SCREEN_WIDTH / 2.0) - (camera_x * scale) + x
		
		# Skip if below horizon from hills
		if projected_y >= max_y:
			# Still accumulate curve/hill even for clipped segments
			dx += segment.curve * SEGMENT_LENGTH * 0.001
			x += dx
			dy += segment.hill * SEGMENT_LENGTH * 0.0005
			y_offset += dy * scale * 100.0
			continue
		
		# Store projected data
		var proj_data = {
			"index": segment_index,
			"segment": segment,
			"y": projected_y,
			"x": projected_x,
			"width": projected_width,
			"scale": scale,
			"z": z_distance,
			"clip_y": max_y
		}
		projected_segments.append(proj_data)
		
		# Update max_y for clipping (hills create horizons)
		if projected_y < max_y:
			max_y = projected_y
		
		# Accumulate curve for next segment
		dx += segment.curve * SEGMENT_LENGTH * 0.001
		x += dx
		
		# Accumulate hill
		dy += segment.hill * SEGMENT_LENGTH * 0.0005
		y_offset += dy * scale * 100.0
		
		# Queue roadside sprites for this segment
		_queue_segment_sprites(segment, proj_data)

func _queue_segment_sprites(segment: TrackSegment, proj_data: Dictionary) -> void:
	for sprite in segment.sprites:
		var sprite_x = proj_data.x + (sprite.x_offset * proj_data.width)
		var sprite_scale = proj_data.scale * sprite.scale
		
		sprite_render_queue.append({
			"sprite": sprite,
			"x": sprite_x,
			"y": proj_data.y,
			"scale": sprite_scale,
			"z": proj_data.z,
			"clip_y": proj_data.clip_y
		})

func _draw_road() -> void:
	# Draw from back to front (painter's algorithm)
	for i in range(projected_segments.size() - 1, 0, -1):
		var p1 = projected_segments[i]      # Far segment
		var p2 = projected_segments[i - 1]  # Near segment
		
		# Determine colors based on segment index (for rumble strips)
		var rumble_index = int(p1.index / RUMBLE_LENGTH) % 2
		var grass_color = track.grass_color_light if rumble_index == 0 else track.grass_color_dark
		var rumble_color = track.rumble_color_light if rumble_index == 0 else track.rumble_color_dark
		var road_color = track.road_color_light if rumble_index == 0 else track.road_color_dark
		
		# Apply fog
		var fog_factor = _calculate_fog(p1.z)
		grass_color = grass_color.lerp(track.horizon_color, fog_factor)
		rumble_color = rumble_color.lerp(track.horizon_color, fog_factor)
		road_color = road_color.lerp(track.horizon_color, fog_factor)
		
		# Calculate segment boundaries
		var y1 = p1.y
		var y2 = p2.y
		
		# Skip if segment is behind us or fully clipped
		if y1 >= y2:
			continue
		if y2 > ROAD_Y:
			y2 = ROAD_Y
		
		# Draw grass (full width background)
		_draw_segment_polygon(
			0, y1, SCREEN_WIDTH, y1,
			SCREEN_WIDTH, y2, 0, y2,
			grass_color
		)
		
		# Calculate road edges
		var road_half_width_1 = p1.width * 0.5
		var road_half_width_2 = p2.width * 0.5
		var rumble_width_1 = p1.width * 0.55
		var rumble_width_2 = p2.width * 0.55
		
		# Draw rumble strips
		_draw_segment_polygon(
			p1.x - rumble_width_1, y1, p1.x + rumble_width_1, y1,
			p2.x + rumble_width_2, y2, p2.x - rumble_width_2, y2,
			rumble_color
		)
		
		# Draw road surface
		_draw_segment_polygon(
			p1.x - road_half_width_1, y1, p1.x + road_half_width_1, y1,
			p2.x + road_half_width_2, y2, p2.x - road_half_width_2, y2,
			road_color
		)
		
		# Draw lane markings
		if rumble_index == 0:
			_draw_lane_markings(p1, p2)

func _draw_segment_polygon(x1: float, y1: float, x2: float, y2: float, 
						   x3: float, y3: float, x4: float, y4: float, color: Color) -> void:
	var points = PackedVector2Array([
		Vector2(x1, y1),
		Vector2(x2, y2),
		Vector2(x3, y3),
		Vector2(x4, y4)
	])
	draw_colored_polygon(points, color)

func _draw_lane_markings(p1: Dictionary, p2: Dictionary) -> void:
	# Center line
	var line_width_1 = p1.width * 0.01
	var line_width_2 = p2.width * 0.01
	
	# Calculate fog for line color
	var fog_factor = _calculate_fog(p1.z)
	var line_color = track.lane_color.lerp(track.horizon_color, fog_factor)
	
	_draw_segment_polygon(
		p1.x - line_width_1, p1.y, p1.x + line_width_1, p1.y,
		p2.x + line_width_2, p2.y, p2.x - line_width_2, p2.y,
		line_color
	)

func _draw_sprites() -> void:
	# Sort sprites by Z (far to near)
	sprite_render_queue.sort_custom(func(a, b): return a.z > b.z)
	
	for sprite_data in sprite_render_queue:
		var sprite: RoadsideSprite = sprite_data.sprite
		var tex = sprite_textures.get(sprite.sprite_type)
		if not tex:
			continue
		
		var scale = sprite_data.scale * 10.0  # Base scale factor
		var width = tex.get_width() * scale
		var height = tex.get_height() * scale
		
		var draw_x = sprite_data.x - (width / 2.0)
		var draw_y = sprite_data.y - height
		
		# Apply fog to sprite
		var fog_factor = _calculate_fog(sprite_data.z)
		var modulate = Color(1, 1, 1, 1).lerp(track.horizon_color, fog_factor * 0.5)
		
		# Draw sprite
		draw_texture_rect(tex, Rect2(draw_x, draw_y, width, height), false, modulate)

func _calculate_fog(z: float) -> float:
	# Exponential fog
	return 1.0 - exp(-z * z / (draw_distance * SEGMENT_LENGTH * fog_density))

# Utility function to check if a world position collides with roadside objects
func check_sprite_collision(world_x: float, world_z: float) -> bool:
	var segment_index = int(world_z / SEGMENT_LENGTH) % track.segments.size()
	var segment = track.segments[segment_index]
	
	for sprite in segment.sprites:
		if not sprite.collidable:
			continue
		
		var sprite_world_x = sprite.x_offset * track.road_width
		var dx = world_x - sprite_world_x
		
		if abs(dx) < sprite.collision_radius:
			return true
	
	return false

# Check if position is off the road
func is_off_road(world_x: float) -> bool:
	var half_road = track.road_width * 0.5
	return abs(world_x) > half_road
