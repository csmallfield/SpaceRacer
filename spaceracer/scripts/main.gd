extends Node2D
## Main - Main game scene that orchestrates all game components

# Node references
var road_renderer: RoadRenderer
var player_car: PlayerCar
var ai_cars: Array[AICar] = []
var hud: RaceHUD
var track: Track

# Game settings
const NUM_AI_CARS: int = 3
const AI_START_SPACING: float = 500.0  # Distance between AI cars at start

func _ready() -> void:
	_setup_track()
	_setup_road_renderer()
	_setup_player()
	_setup_ai_cars()
	_setup_hud()
	
	# Start countdown after a short delay
	await get_tree().create_timer(0.5).timeout
	hud.start_countdown()

func _setup_track() -> void:
	track = Track.create_test_track()
	_populate_track_with_scenery()
	GameManager.current_track = track

func _populate_track_with_scenery() -> void:
	# Add roadside scenery to track segments
	var segment_count = track.segments.size()
	
	for i in range(segment_count):
		var segment = track.segments[i]
		
		# Add trees/rocks on both sides periodically
		if i % 5 == 0:
			segment.add_sprite("tree", -1.4, randf_range(0.8, 1.2))
			segment.add_sprite("tree", 1.4, randf_range(0.8, 1.2))
		
		if i % 8 == 0:
			segment.add_sprite("rock", -1.6, randf_range(0.6, 1.0))
		
		if i % 12 == 0:
			segment.add_sprite("building", 1.8, randf_range(0.8, 1.5))
		
		if i % 15 == 0:
			segment.add_sprite("sign", -1.2, 0.8)

func _setup_road_renderer() -> void:
	road_renderer = RoadRenderer.new()
	road_renderer.set_track(track)
	road_renderer.name = "RoadRenderer"
	add_child(road_renderer)

func _setup_player() -> void:
	player_car = PlayerCar.new()
	player_car.name = "PlayerCar"
	player_car.car_id = 0
	player_car.setup(road_renderer, track)
	player_car.world_z = 200.0  # Start position
	add_child(player_car)
	
	# Connect signals
	player_car.speed_changed.connect(_on_player_speed_changed)

func _setup_ai_cars() -> void:
	var ai_colors = [
		Color(0.2, 0.3, 0.9),  # Blue
		Color(0.1, 0.7, 0.2),  # Green  
		Color(0.9, 0.6, 0.1),  # Orange
	]
	
	var ai_difficulties = [
		AICar.Difficulty.EASY,
		AICar.Difficulty.MEDIUM,
		AICar.Difficulty.HARD,
	]
	
	for i in range(NUM_AI_CARS):
		var ai = AICar.new()
		ai.name = "AICar_%d" % i
		ai.car_id = i + 1
		ai.difficulty = ai_difficulties[i % ai_difficulties.size()]
		ai.car_color = ai_colors[i % ai_colors.size()]
		
		# Position AI cars ahead of player
		var start_z = 200.0 + ((i + 1) * AI_START_SPACING)
		var start_x = (i - 1) * 200.0  # Spread across lanes
		ai.setup(road_renderer, track, start_z, start_x)
		
		add_child(ai)
		ai_cars.append(ai)

func _setup_hud() -> void:
	hud = RaceHUD.new()
	hud.name = "HUD"
	hud.total_cars = NUM_AI_CARS + 1
	hud.total_laps = GameManager.total_laps
	add_child(hud)

func _on_player_speed_changed(speed: float, max_speed: float) -> void:
	hud.update_speed(speed, max_speed)

func _input(event: InputEvent) -> void:
	# Debug/utility controls
	if event.is_action_pressed("ui_cancel"):
		# Reset race
		_reset_race()
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				_reset_race()
			KEY_F1:
				_toggle_debug_info()

func _reset_race() -> void:
	# Reset all positions
	player_car.reset_position()
	player_car.world_z = 200.0
	
	for i in range(ai_cars.size()):
		var ai = ai_cars[i]
		ai.world_z = 200.0 + ((i + 1) * AI_START_SPACING)
		ai.world_x = (i - 1) * 200.0
		ai.speed = 0.0
	
	GameManager.reset_race()
	
	# Restart countdown
	hud.start_countdown()

func _toggle_debug_info() -> void:
	# Could add debug overlay here
	print("Player Z: %.1f, X: %.1f, Speed: %.1f" % [
		player_car.world_z, 
		player_car.world_x, 
		player_car.speed
	])
	print("Track length: %.1f" % track.track_length)
