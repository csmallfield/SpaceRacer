extends Node
class_name GameManager

# Main game manager - coordinates player and road renderer

@onready var road_renderer: RoadRenderer = $RoadRenderer
@onready var player: Player = Player.new()
@onready var hud: Control = $HUD

func _ready():
	# Initialize player
	add_child(player)
	
	# Connect player to road renderer
	road_renderer.player = player
	
	# Update HUD labels
	update_hud()
	
	print("Pseudo 3D Racer initialized!")
	print("Controls:")
	print("  W / Up Arrow - Accelerate")
	print("  S / Down Arrow - Brake")
	print("  A / Left Arrow - Steer Left")
	print("  D / Right Arrow - Steer Right")

func _process(delta: float) -> void:
	# Get current segment for player
	var current_segment_index: int = player.get_segment_index(
		road_renderer.segments, 
		road_renderer.track_length
	)
	var current_segment: RoadSegment = null
	if current_segment_index >= 0 and current_segment_index < road_renderer.segments.size():
		current_segment = road_renderer.segments[current_segment_index]
	
	# Update player
	player.update(delta, current_segment)
	
	# Update HUD
	update_hud()

func update_hud() -> void:
	if hud:
		var speed_label = hud.get_node_or_null("SpeedLabel")
		var position_label = hud.get_node_or_null("PositionLabel")
		var lap_label = hud.get_node_or_null("LapLabel")
		
		if speed_label:
			speed_label.text = "Speed: %d mph" % int(player.speed)
		
		if position_label:
			var progress: float = fmod(player.position, road_renderer.track_length)
			if progress < 0:
				progress += road_renderer.track_length
			var percentage: float = (progress / road_renderer.track_length) * 100.0
			position_label.text = "Track: %.1f%%" % percentage
		
		if lap_label:
			var lap: int = int(player.position / road_renderer.track_length)
			lap_label.text = "Lap: %d" % (lap + 1)
