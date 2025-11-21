extends Node2D
class_name RoadRenderer

# Road rendering using pseudo-3D technique (Mode 7 / OutRun style)

# Rendering parameters
const ROAD_WIDTH: float = 2000.0  # Width of road in world units
const SEGMENT_LENGTH: float = 200.0  # Length of each segment
const DRAW_DISTANCE: float = 500  # How many segments to draw
const FOV: float = 100.0  # Field of view
const CAMERA_HEIGHT: float = 1000.0  # Camera height above road
const CAMERA_DEPTH: float = 1.0 / CAMERA_HEIGHT  # For projection calculations

# Colors
const ROAD_COLOR_1: Color = Color(0.4, 0.4, 0.4)  # Dark asphalt
const ROAD_COLOR_2: Color = Color(0.5, 0.5, 0.5)  # Light asphalt
const GRASS_COLOR: Color = Color(0.0, 0.6, 0.0)  # Grass
const RUMBLE_COLOR_1: Color = Color(1.0, 1.0, 1.0)  # White rumble strip
const RUMBLE_COLOR_2: Color = Color(1.0, 0.0, 0.0)  # Red rumble strip
const LINE_COLOR: Color = Color(1.0, 1.0, 1.0)  # Center line

# Road segments
var segments: Array[RoadSegment] = []
var track_length: float = 0.0

# Reference to player
var player: Player

func _ready():
	# Create the track
	create_track()

func create_track() -> void:
	# Create a looping track with various curves and hills
	segments.clear()
	
	var z_pos: float = 0.0
	var y_pos: float = 0.0
	var num_segments: int = 500  # Total segments in track
	
	# Build segments with curves and hills
	for i in range(num_segments):
		var segment = RoadSegment.new()
		segment.z = z_pos
		segment.y = y_pos
		
		# Create varied track sections
		var progress: float = float(i) / float(num_segments)
		
		# Curves - create interesting combinations
		if progress < 0.15:  # Straight
			segment.curve = 0.0
		elif progress < 0.25:  # Right curve
			segment.curve = 1.5
		elif progress < 0.35:  # Straight
			segment.curve = 0.0
		elif progress < 0.5:  # Long left curve
			segment.curve = -1.2
		elif progress < 0.6:  # Straight
			segment.curve = 0.0
		elif progress < 0.65:  # Sharp right
			segment.curve = 2.5
		elif progress < 0.75:  # S-curve (right to left)
			if progress < 0.7:
				segment.curve = 1.5
			else:
				segment.curve = -1.5
		else:  # Straight to finish
			segment.curve = 0.0
		
		# Hills - add elevation changes
		if progress < 0.1:
			y_pos += 10.0  # Uphill
		elif progress < 0.2:
			y_pos -= 5.0  # Slight downhill
		elif progress < 0.4:
			y_pos += 0.0  # Flat
		elif progress < 0.45:
			y_pos += 50.0  # Big hill
		elif progress < 0.55:
			y_pos -= 30.0  # Down the hill
		elif progress < 0.8:
			y_pos += 2.0  # Slight uphill
		else:
			y_pos -= 2.0  # Back to start level
		
		segment.y = y_pos
		
		# Alternate colors for road stripes
		segment.is_striped = (i % 4) < 2
		
		segments.append(segment)
		z_pos += SEGMENT_LENGTH
	
	track_length = z_pos
	print("Track created with ", segments.size(), " segments, length: ", track_length)

func _draw():
	if not player:
		return
	
	# Get screen dimensions
	var screen_width: float = get_viewport_rect().size.x
	var screen_height: float = get_viewport_rect().size.y
	var half_width: float = screen_width / 2.0
	var half_height: float = screen_height / 2.0
	
	# Clear background - draw sky
	draw_rect(Rect2(0, 0, screen_width, screen_height), Color(0.5, 0.7, 1.0))
	
	# Find base segment (where player is)
	var base_index: int = player.get_segment_index(segments, track_length)
	var base_segment: RoadSegment = segments[base_index]
	
	# Calculate projection for visible segments
	var base_percent: float = fmod(player.position, SEGMENT_LENGTH) / SEGMENT_LENGTH
	
	var max_y: float = screen_height  # Track highest drawn Y (for clipping)
	var curve_offset: float = 0.0  # Accumulated curve offset
	var curve_delta: float = 0.0  # Rate of curve change
	
	# Draw segments from far to near
	var draw_start: int = base_index
	var draw_end: int = base_index + int(DRAW_DISTANCE)
	
	for n in range(draw_start, draw_end):
		var i: int = n % segments.size()
		var segment: RoadSegment = segments[i]
		
		# Calculate distance from camera
		var segment_distance: float = float(n - base_index)
		var z: float = ((segment_distance + 1.0) - base_percent) * SEGMENT_LENGTH
		
		# Skip if too close
		if z < SEGMENT_LENGTH * 0.5:
			continue
		
		# 3D to 2D projection
		segment.scale = 300 / z 
		var camera_y: float = player.y + base_segment.y
		var proj_y: float = (camera_y - segment.y) * segment.scale
		segment.clip = half_height + proj_y
		
		# Debug output for first few segments
		#if n < base_index + 3:
		#	print("Segment ", n, ": z=", z, " scale=", segment.scale, " clip=", segment.clip, " road_width=", ROAD_WIDTH * segment.scale)
		
		# Skip segments that are off-screen (above horizon)
		if segment.clip >= max_y:
			continue
		
		# Calculate curve offset
		curve_delta += segment.curve
		curve_offset += curve_delta
		
		# Project road width and position
		var road_width: float = ROAD_WIDTH * segment.scale
		var x_offset: float = (curve_offset - player.x * 1000.0) * segment.scale
		
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
		
		max_y = y1
	
	# Draw player car (simple rectangle for now)
	draw_player_car(screen_width, screen_height)
	
	# Draw simple HUD
	draw_hud(screen_width, screen_height)

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

func _process(_delta: float) -> void:
	queue_redraw()  # Continuously redraw
