class_name Track
extends Resource
## Track - Resource containing all track segment data for the pseudo-3D road

@export var name: String = "Untitled Track"
@export var segments: Array[TrackSegment] = []
@export var track_length: float = 0.0  # Total length in world units

# Road appearance
@export var road_width: float = 2000.0  # Width of road at z=1
@export var rumble_width: float = 200.0  # Width of rumble strips
@export var lane_count: int = 3

# Colors
@export var road_color_light: Color = Color(0.4, 0.4, 0.4)
@export var road_color_dark: Color = Color(0.35, 0.35, 0.35)
@export var rumble_color_light: Color = Color(1.0, 0.0, 0.0)
@export var rumble_color_dark: Color = Color(1.0, 1.0, 1.0)
@export var grass_color_light: Color = Color(0.1, 0.6, 0.1)
@export var grass_color_dark: Color = Color(0.0, 0.5, 0.0)
@export var lane_color: Color = Color(1.0, 1.0, 1.0)

# Sky/horizon
@export var sky_color: Color = Color(0.4, 0.7, 1.0)
@export var horizon_color: Color = Color(0.8, 0.9, 1.0)

func _init() -> void:
	segments = []

func add_segment(curve: float, hill: float, length: float = 200.0) -> void:
	var seg = TrackSegment.new()
	seg.curve = curve
	seg.hill = hill
	seg.length = length
	seg.index = segments.size()
	seg.start_z = track_length
	segments.append(seg)
	track_length += length

func add_straight(length: float, hill: float = 0.0) -> void:
	add_segment(0.0, hill, length)

func add_curve_left(length: float, sharpness: float = 1.0, hill: float = 0.0) -> void:
	add_segment(-sharpness, hill, length)

func add_curve_right(length: float, sharpness: float = 1.0, hill: float = 0.0) -> void:
	add_segment(sharpness, hill, length)

func add_hill_up(length: float, steepness: float = 1.0, curve: float = 0.0) -> void:
	add_segment(curve, steepness, length)

func add_hill_down(length: float, steepness: float = 1.0, curve: float = 0.0) -> void:
	add_segment(curve, -steepness, length)

func add_s_curve(length: float, sharpness: float = 1.0, hill: float = 0.0) -> void:
	add_curve_left(length / 2.0, sharpness, hill)
	add_curve_right(length / 2.0, sharpness, hill)

func get_segment_at_z(z: float) -> TrackSegment:
	# Wrap z around track length for looping
	z = fmod(z, track_length)
	if z < 0:
		z += track_length
	
	# Binary search for segment
	var low = 0
	var high = segments.size() - 1
	
	while low <= high:
		var mid = (low + high) / 2
		var seg = segments[mid]
		if z >= seg.start_z and z < seg.start_z + seg.length:
			return seg
		elif z < seg.start_z:
			high = mid - 1
		else:
			low = mid + 1
	
	return segments[0] if segments.size() > 0 else null

func get_segment_index_at_z(z: float) -> int:
	var seg = get_segment_at_z(z)
	return seg.index if seg else 0

func get_position_percent(z: float) -> float:
	if track_length <= 0:
		return 0.0
	return fmod(z, track_length) / track_length

# Generate a default test track
static func create_test_track() -> Track:
	var track = Track.new()
	track.name = "Test Circuit"
	
	# Starting straight
	track.add_straight(3000.0)
	
	# First curve (gentle right)
	track.add_curve_right(2000.0, 0.8)
	
	# Short straight with small hill
	track.add_hill_up(1000.0, 1.5)
	track.add_hill_down(1000.0, 1.5)
	
	# S-curve
	track.add_s_curve(3000.0, 1.2)
	
	# Long curve left
	track.add_curve_left(2500.0, 1.0)
	
	# Downhill straight
	track.add_hill_down(1500.0, 2.0)
	
	# Sharp right turn
	track.add_curve_right(1500.0, 2.0)
	
	# Rolling hills
	track.add_hill_up(800.0, 1.0)
	track.add_hill_down(600.0, 0.8)
	track.add_hill_up(600.0, 0.8)
	track.add_hill_down(800.0, 1.0)
	
	# Final curve back to start
	track.add_curve_left(2000.0, 0.6)
	
	# Final straight to finish line
	track.add_straight(2500.0)
	
	return track
